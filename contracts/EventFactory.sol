//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IEventFactory, EventInfo, Transferable} from "./interfaces/IEventFactory.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "./Nonces.sol";

contract EventFactory is EIP712, Nonces {
    address immutable GATEWAY;

    mapping(address => address[]) public CreatorPublicEvents;

    bytes32 private constant EC_TYPEHASH =
        keccak256(
            "EventCreation(EventInfo( bool Virtual,uint8 Transferable,uint8 Type,uint8 Limit,uint64 UTCtime,address Creator,uint128 Price,uint128 TotalSupply,bytes32 LocationHash,string Name,string Description,string[] Tags),uint256 nonce,uint256 deadline)"
        );

    constructor(address gateway) EIP712("EvenetFactory", "1.0.0") {
        require(gateway != address(0), "EventFactory: NULL_GATEWAY");

        GATEWAY = gateway;
    }

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address gateway);

    function createEvent(
        EventInfo calldata eventInfo,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (block.timestamp > deadline)
            revert ERC2612ExpiredSignature(deadline);

        bytes32 structHash = keccak256(
            abi.encode(EC_TYPEHASH, eventInfo, _useNonce(msg.sender), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        if (ECDSA.recover(hash, signature) != GATEWAY)
            revert ERC2612InvalidSigner(
                ECDSA.recover(hash, signature),
                GATEWAY
            );

        
    }
}
