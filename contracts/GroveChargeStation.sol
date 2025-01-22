//  SPDX-License-Identifier: -- Grove --
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUSDCswapper} from "./interfaces/IUSDCswapper.sol";

contract GroveChargeStation {
    IERC20 public immutable USDC;
    IUSDCswapper public immutable USDC_SWAPPER;

    mapping(address => uint256) public platformUSDCbalance;

    event Charged(
        address indexed chargedFor,
        uint256 indexed amountInUSDC,
        address indexed platform,
        address charger
    );

    event USDCtransferedByPlatform(
        address indexed to,
        uint256 indexed amountInUSDC,
        address indexed platform,
        uint256 currentPlatformUSDCbalance
    );

    constructor(address usdc, address swapper) {
        require(
            usdc != address(0) && swapper != address(0),
            "GroveChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        USDC = IERC20(usdc);
        USDC_SWAPPER = IUSDCswapper(swapper);
    }

    function charge(
        address for_,
        address token,
        uint256 amount,
        address[] calldata helpPath,
        address platform
    ) external {
        require(
            token != address(0),
            "GroveChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        require(amount != 0, "GroveChargeStation: ZERO_AMOUNT_PROVIDED");
        require(
            platform != address(0),
            "GroveChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        if (for_ == address(0)) for_ = msg.sender;

        uint256 amountInUSDC;
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (token == address(USDC)) {
            amountInUSDC = amount;

            emit Charged(for_, amountInUSDC, platform, msg.sender);
        } else {
            // TODO: SWAP INTO USDC
            USDC_SWAPPER.isSwappable(token, amount, helpPath);
            amountInUSDC = USDC_SWAPPER.swapIntoUSDC(token, amount, helpPath);

            emit Charged(for_, amountInUSDC, platform, msg.sender);
        }

        platformUSDCbalance[platform] += amountInUSDC;
    }

    function transferUSDC(address to, uint256 amount) external {
        require(
            platformUSDCbalance[msg.sender] >= amount,
            "GroveChargeStation: INSUFFICIENT_USDC_BALANCE"
        );

        unchecked {
            platformUSDCbalance[msg.sender] -= amount;
        }

        USDC.transfer(to, amount);

        emit USDCtransferedByPlatform(
            to,
            amount,
            msg.sender,
            platformUSDCbalance[msg.sender]
        );
    }
}
