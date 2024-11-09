//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StampPaymentStation {
    enum EventStatus {
        open,
        canceled,
        collected
    }

    struct PaymentDetails {
        address payer;
        string symbol;
        uint256 amount;
        bytes32 sigHash;
    }

    mapping(string => address) public symbolToAddress;
    mapping(bytes32 => PaymentDetails) public hashToData;
    mapping(address => uint256) public chainNonce;
    mapping(bytes32 => mapping(string => uint256)) public balance;
    mapping(bytes32 => EventStatus) public stat;
    mapping(string => uint256) public pendingFee;
    mapping(string => uint256) public collectedFee;

    uint256 private constant BASIS = 1e5;
    uint256 private constant STAMP_BIAS = 5e4;

    event PaymentArrived(
        address indexed payer,
        string token,
        uint256 indexed amount,
        bytes32 indexed sigHash
    );

    function pay(
        string calldata paymentToken,
        uint256 amount,
        bytes32 sigHash
    ) external {
        require(sigHash != bytes32(0), "SPS: NULL_SIGHASH");
        require(stat[sigHash] == EventStatus.open, "SPS: CLOSED");

        require(
            keccak256(abi.encodePacked(paymentToken)) == keccak256("") ||
                (isTokenSupported(paymentToken) && amount != 0),
            "SPS: INVALID_PAYMENT_TOKEN"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(sigHash, msg.sender, chainNonce[msg.sender])
        );

        require(
            hashToData[hash].payer == address(0),
            "SPS: HASH_REGISTERED_BEFORE"
        );

        if (
            keccak256(abi.encodePacked(paymentToken)) != keccak256("") &&
            amount != 0
        ) {
            IERC20(symbolToAddress[paymentToken]).transferFrom(
                msg.sender,
                address(this),
                amount
            );

            pendingFee[paymentToken] += (amount * BASIS) / STAMP_BIAS;

            balance[sigHash][paymentToken] +=
                amount -
                ((amount * BASIS) / STAMP_BIAS);
        }

        chainNonce[msg.sender]++;
        hashToData[hash] = PaymentDetails(
            msg.sender,
            paymentToken,
            amount,
            sigHash
        );

        emit PaymentArrived(msg.sender, paymentToken, amount, sigHash);
    }

    function isTokenSupported(string calldata tokenSymbol)
        public
        view
        returns (bool)
    {
        return symbolToAddress[tokenSymbol] != address(0);
    }
}
