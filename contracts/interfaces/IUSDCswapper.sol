//  SPDX-License-Identifier: -- Grove --
pragma solidity 0.8.25;

interface IUSDCswapper {
    function isSwappable(
        address token,
        uint256 amount,
        address[] calldata helpPath
    ) external view returns (bool);

    function swapIntoUSDC(
        address token,
        uint256 amount,
        address[] calldata helpPath
    ) external returns(uint256);
}
