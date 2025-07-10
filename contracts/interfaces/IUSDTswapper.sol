//  SPDX-License-Identifier: -- Ewana --
pragma solidity 0.8.25;

interface IUSDTswapper {
    function isSwappable(
        address token,
        uint256 amount,
        address[] calldata helpPath
    ) external view returns (bool);

    function swapIntoUSDT(
        address token,
        uint256 amount,
        address[] calldata helpPath
    ) external returns(uint256);
}
