//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StampPaymentStation {
    IERC20 public USDT;
    IERC20 public USDC;
    address public UNI_V3_ROUTER;
    mapping(string => address) public paymentTokens;
    mapping(bytes32 => bool) public hashed;
    mapping(address => uint256) public chainNonce;
    mapping(bytes32 => mapping(string => uint256)) public balance;

    function pay(
        string calldata paymentToken,
        uint256 amount,
        bytes32 sigHash
    ) external {
        require(
            keccak256(abi.encodePacked(paymentToken)) == keccak256("") ||
                (paymentTokens[paymentToken] != address(0) && amount != 0),
            "SPS: INVALID_PAYMENT_TOKEN"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(sigHash, msg.sender, chainNonce[msg.sender])
        );

        require(!hashed[hash], "SPS: HASH_REGISTERED_BEFORE");

        if (keccak256(abi.encodePacked(paymentToken)) != keccak256(""))
            IERC20(paymentTokens[paymentToken]).transferFrom(
                msg.sender,
                address(this),
                amount
            );

        chainNonce[msg.sender]++;
        hashed[hash] = true;
    }

    // function checkToken(uint256 token) private view {
    //     paymentTokens
    // }
}
