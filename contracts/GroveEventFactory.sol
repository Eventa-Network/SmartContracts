//  SPDX-License-Identifier: -- GROVE --
pragma solidity 0.8.25;

import {IGroveEventFactory, EventInfo, Transferable} from "./interfaces/IGroveEventFactory.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "./Nonces.sol";
import {ClonesWithImmutableArgs} from "./libs/ClonesWithImmutableArgs.sol";

import {GroveEvent} from "./GroveEvent.sol";

contract GroveEventFactory is EIP712, Nonces, IGroveEventFactory {
    address public immutable GATEWAY;
    address public immutable IMPLEMENTATION;

    mapping(address => address[]) public CreatorPublicEvents;

    bytes32 private constant EC_TYPEHASH =
        keccak256(
            "EventCreation(bool Virtual,uint8 Transferable,uint8 Type,uint8 Limit,uint32 UTCstartTime,uint32 UTCendTime,address Creator,uint128 Price,uint128 TotalSupply,bytes32 LocationRefHash,bytes32 PublicDescRefHash,bytes32 PrivateDescRefHash,string Name,string[3] Tags,uint256 Nonce)"
        );

    constructor(address gateway) EIP712("GroveEventFactory", "1.0.0") {
        require(gateway != address(0), "GroveEventFactory: NULL_GATEWAY");

        GATEWAY = gateway;

        IMPLEMENTATION = address(new GroveEvent());
    }

    function createEvent(EventInfo calldata eventInfo, bytes calldata signature)
        external
    {
        require(
            tx.origin == eventInfo.Creator,
            "GroveEventFactory: ACCESS_DENIED"
        );

        bytes32 structHash = keccak256(
            bytes.concat(
                abi.encode(
                    EC_TYPEHASH,
                    eventInfo.Virtual,
                    eventInfo.Transferable,
                    eventInfo.Type,
                    eventInfo.Limit,
                    eventInfo.UTCstartTime,
                    eventInfo.UTCendTime,
                    eventInfo.Creator,
                    eventInfo.Price,
                    eventInfo.TotalSupply
                ),
                abi.encodePacked(
                    eventInfo.LocationRefHash,
                    eventInfo.PublicDescRefHash,
                    eventInfo.PrivateDescRefHash,
                    keccak256(bytes(eventInfo.Name))
                ),
                abi.encodePacked(
                    keccak256(
                        abi.encodePacked(
                            keccak256(bytes(eventInfo.Tags[0])),
                            keccak256(bytes(eventInfo.Tags[1])),
                            keccak256(bytes(eventInfo.Tags[2]))
                        )
                    )
                ),
                abi.encodePacked(_useNonce(tx.origin))
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        require(
            ECDSA.recover(hash, signature) == GATEWAY,
            "GroveEventFactory: ERC2612_INVALID_SIGNER"
        );

        address clonedEvent = ClonesWithImmutableArgs.clone3(
            IMPLEMENTATION,
            abi.encodePacked(
                eventInfo.Virtual,
                eventInfo.Transferable,
                eventInfo.Type,
                eventInfo.Creator,
                address(this)
            ),
            hash
        );

        // ANTI DEEP STACK
        bytes32[3] memory ADS_HASHED_DATA = [
            eventInfo.LocationRefHash,
            eventInfo.PublicDescRefHash,
            eventInfo.PrivateDescRefHash
        ];
        string[4] memory ADS_STRING = [
            eventInfo.Name,
            eventInfo.Tags[0],
            eventInfo.Tags[1],
            eventInfo.Tags[2]
        ];

        GroveEvent(clonedEvent).init(
            eventInfo.UTCstartTime,
            eventInfo.UTCendTime,
            eventInfo.Price,
            eventInfo.TotalSupply,
            ADS_HASHED_DATA[0],
            ADS_HASHED_DATA[1],
            ADS_HASHED_DATA[2],
            ADS_STRING[0],
            [ADS_STRING[1], ADS_STRING[2], ADS_STRING[3]]
        );

        emit EventCreated(
            eventInfo,
            clonedEvent,
            nonces(eventInfo.Creator) - 1
        );
    }

    function getPreAddressAndNonce(EventInfo calldata eventInfo)
        external
        view
        returns (address preDeployedAddress, uint256 nonce)
    {
        nonce = nonces(eventInfo.Creator);

        bytes32 structHash = keccak256(
            bytes.concat(
                abi.encode(
                    EC_TYPEHASH,
                    eventInfo.Virtual,
                    eventInfo.Transferable,
                    eventInfo.Type,
                    eventInfo.Limit,
                    eventInfo.UTCstartTime,
                    eventInfo.UTCendTime,
                    eventInfo.Creator,
                    eventInfo.Price,
                    eventInfo.TotalSupply
                ),
                abi.encodePacked(
                    eventInfo.LocationRefHash,
                    eventInfo.PublicDescRefHash,
                    eventInfo.PrivateDescRefHash,
                    keccak256(bytes(eventInfo.Name))
                ),
                abi.encodePacked(
                    keccak256(
                        abi.encodePacked(
                            keccak256(bytes(eventInfo.Tags[0])),
                            keccak256(bytes(eventInfo.Tags[1])),
                            keccak256(bytes(eventInfo.Tags[2]))
                        )
                    )
                ),
                abi.encodePacked(nonce)
            )
        );

        preDeployedAddress = ClonesWithImmutableArgs.addressOfClone3(
            _hashTypedDataV4(structHash)
        );
    }
}
