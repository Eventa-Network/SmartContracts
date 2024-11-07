//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

contract StampPaymentStation {
    struct PaymentInfo {
        
        uint256 spent;
    }

    mapping(bytes32 => uint256) public hashToPaymentInfo;
}
