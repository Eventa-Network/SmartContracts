// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract FakeERC20 {
    string public name = "USD Coin";
    string public symbol = "USDC";
    uint256 public decimals = 18;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {}
}
