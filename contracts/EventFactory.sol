//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IEventFactory, EventInfo, Transferable} from "./interfaces/IEventFactory.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "./Nonces.sol";
import {ClonesWithImmutableArgs} from "./libs/ClonesWithImmutableArgs.sol";

import {Event} from "./Event.sol";

contract EventFactory is EIP712, Nonces, IEventFactory {
    using ClonesWithImmutableArgs for address;

    address public immutable GATEWAY;
    address public immutable IMPLEMENTATION;

    mapping(address => address[]) public CreatorPublicEvents;

    bytes32 private constant EC_TYPEHASH =
        keccak256(
            "EventCreation(EventInfo(bool Virtual,uint8 Transferable,uint8 Type,uint8 Limit,uint64 UTCtime,address Creator,uint128 Price,uint128 TotalSupply,bytes32 LocationRefHash,bytes32 PublicDescRefHash,bytes32 PrivateDescRefHash,string Name,string[] Tags),uint256 nonce)"
        );

    constructor(address gateway) EIP712("EvenetFactory", "1.0.0") {
        require(gateway != address(0), "EventFactory: NULL_GATEWAY");

        GATEWAY = gateway;

        IMPLEMENTATION = address(new Event());
    }

    error AccessDenied(address caller, address callee);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address gateway);

    function createEvent(EventInfo calldata eventInfo, bytes calldata signature)
        external
    {
        if (tx.origin != eventInfo.Creator)
            revert AccessDenied(tx.origin, eventInfo.Creator);

        bytes32 structHash = keccak256(
            abi.encode(EC_TYPEHASH, eventInfo, _useNonce(tx.origin))
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        if (ECDSA.recover(hash, signature) != GATEWAY)
            revert ERC2612InvalidSigner(
                ECDSA.recover(hash, signature),
                GATEWAY
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

        Event(clonedEvent).init(
            eventInfo.UTCtime,
            eventInfo.Price,
            eventInfo.TotalSupply,
            eventInfo.LocationRefHash,
            eventInfo.PublicDescRefHash,
            eventInfo.PrivateDescRefHash,
            eventInfo.Name,
            eventInfo.Tags
        );

        emit EventCreated(eventInfo, clonedEvent, nonces(eventInfo.Creator));
    }

    function getPreAddressAndNonce(EventInfo calldata eventInfo)
        external
        view
        returns (address, uint256)
    {
        bytes32 structHash = keccak256(
            abi.encode(EC_TYPEHASH, eventInfo, nonces(eventInfo.Creator) + 1)
        );

        bytes32 salt = _hashTypedDataV4(structHash);
        return (
            ClonesWithImmutableArgs.addressOfClone3(salt),
            nonces(eventInfo.Creator)
        );
    }
}
