//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

contract StampPaymentStation {
    enum PaymentToken {
        USDT,
        USDC
    }
    mapping(address => uint256) public chainNonce;
    mapping(bytes32 => bool) public hashed;

    function pay(
        PaymentToken paymentToken,
        PaymentToken destinationToken,
        uint256 amount,
        bytes32 hash,
        bytes32 sigHash
    ) external {
        require(!hashed[hash], "SPS: HASH_REGISTERED_BEFORE");
        

        chainNonce[msg.sender]++;
    }
}
