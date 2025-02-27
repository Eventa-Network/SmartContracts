// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract FakeERC20 {
    string public name = "USD Coin";
    string public symbol = "USDC";
    uint256 public decimals = 18;

    function approve(address spender, uint256 amount) external returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {}
}
