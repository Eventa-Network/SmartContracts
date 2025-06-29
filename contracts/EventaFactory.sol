//  SPDX-License-Identifier: -- Ewana --
pragma solidity 0.8.25;

import {IEventaFactory, EventInfo, Transferable} from "./interfaces/IEventaFactory.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "./Nonces.sol";
import {ClonesWithImmutableArgs} from "./libs/ClonesWithImmutableArgs.sol";
import {Eventa} from "./Eventa.sol";

contract EventaFactory is EIP712, Nonces, IEventaFactory {
    address public immutable GATEWAY;
    address public immutable IMPLEMENTATION;
    address[] public allEvents;
    mapping(address => address[]) public CreatorPublicEvents;

    bytes32 private constant EC_TYPEHASH =
        keccak256(
            "EventCreation(bool Virtual,uint8 Transferable,uint8 Type,uint8 Limit,uint32 UTCstartTime,uint32 UTCendTime,address Creator,uint128 Price,uint128 TotalSupply,bytes32 LocationRefHash,bytes32 PublicDescRefHash,bytes32 PrivateDescRefHash,string Name,string[3] Tags,uint256 Nonce)"
        );

    constructor(address gateway) EIP712("EventaFactory", "1.0.0") {
        require(gateway != address(0), "EventaFactory: NULL_GATEWAY");

        GATEWAY = gateway;

        IMPLEMENTATION = address(new Eventa());
    }

    function createEvent(EventInfo calldata eventInfo, bytes calldata signature)
        external
    {
        require(
            tx.origin == eventInfo.Creator,
            "EventaFactory: ACCESS_DENIED"
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
            "EventaFactory: ERC2612_INVALID_SIGNER"
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

        allEvents.push(clonedEvent);

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

        Eventa(clonedEvent).init(
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

    function paginatedEvents(uint256 page)
        external
        view
        returns (
            uint256 currentPage,
            uint256 totalPages,
            address[] memory paggedArray
        )
    {
        if (allEvents.length == 0)
            return (currentPage, totalPages, paggedArray);
        else if (allEvents.length < 11) {
            paggedArray = new address[](allEvents.length);

            uint256 x;
            while (true) {
                paggedArray[x] = allEvents[allEvents.length - 1 - x];

                if (x == allEvents.length - 1) break;

                unchecked {
                    x++;
                }
            }

            return (1, 1, paggedArray);
        }

        if (page == 0) page = 1;

        totalPages = allEvents.length / 10;

        uint256 diffLength = allEvents.length - (totalPages * 10);

        if (totalPages * 10 < allEvents.length) totalPages++;
        if (page > totalPages) page = totalPages;
        currentPage = page;

        uint256 firstIndex;
        uint256 lastIndex;
        if (page == 1) {
            firstIndex = allEvents.length - 1;
            lastIndex = firstIndex - 10;
        } else if (page == totalPages)
            firstIndex = diffLength == 0 ? firstIndex = 9 : diffLength - 1;
        else {
            firstIndex +=
                ((totalPages - page) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
            lastIndex +=
                ((totalPages - page - 1) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
        }

        paggedArray = new address[]((firstIndex + 1) - lastIndex);

        uint256 i;
        while (true) {
            paggedArray[i] = allEvents[firstIndex];

            if (firstIndex == lastIndex) break;
            unchecked {
                i++;
                firstIndex--;
            }
        }
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
