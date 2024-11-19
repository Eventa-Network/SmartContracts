//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "./Nonces.sol";

contract Stamper is EIP712, Nonces {
    struct SignHashInfo {
        uint128 total;
        uint128 balance;
    }

    mapping(bytes32 => SignHashInfo) public signHashInfo;
    mapping(address => mapping(bytes32 => uint256)) public purchasedTicket;

    address immutable GATEWAY;

    event TicketPurchased(bytes32 signHash, address buyer);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address gateway);
    bytes32 private constant TP_TYPEHASH =
        keccak256(
            "TicketPurchase(bytes32 signHash,uint256 ticketPrice,uint256 total,address buyer,uint256 nonce)"
        );

    constructor(address gateway) EIP712("Stamper", "1.0.0") {
        require(gateway != address(0), "Stamper: NULL_GATEWAY");

        GATEWAY = gateway;
    }

    function buyTicket(
        bytes32 signHash,
        uint256 ticketPrice,
        uint256 total,
        bytes calldata signature
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                TP_TYPEHASH,
                signHash,
                ticketPrice,
                total,
                tx.origin,
                _useNonce(tx.origin)
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        if (ECDSA.recover(hash, signature) != GATEWAY)
            revert ERC2612InvalidSigner(
                ECDSA.recover(hash, signature),
                GATEWAY
            );

        unchecked {
            purchasedTicket[tx.origin][signHash] += total;

            signHashInfo[signHash].total++;
            signHashInfo[signHash].balance += uint128(ticketPrice);
        }

        emit TicketPurchased(signHash, tx.origin);
    }
}
