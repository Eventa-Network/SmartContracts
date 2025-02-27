//  SPDX-License-Identifier: -- Grove --
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUSDCswapper} from "./interfaces/IUSDCswapper.sol";

contract GroveChargeStation {
    struct UserTX {
        address user;
        address platform;
        address token;
        uint256 tokenAmount;
        uint256 amountInUSDC;
        bytes32 txID;
    }

    IERC20 public immutable USDC;
    IUSDCswapper public immutable USDC_SWAPPER;

    UserTX[] public usersTXs;
    mapping(address => uint256) public platformUSDCbalance;
    mapping(address => uint256) public userNonce;

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
        usersTXs.push(
            UserTX(
                for_,
                platform,
                token,
                amount,
                amountInUSDC,
                (keccak256(abi.encodePacked(for_, userNonce[for_])))
            )
        );
        userNonce[for_]++;
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

    function paginatedUsersTXs(uint256 page)
        external
        view
        returns (
            uint256 currentPage,
            uint256 totalPages,
            UserTX[] memory paggedArray
        )
    {
        if (usersTXs.length == 0)
            return (currentPage, totalPages, paggedArray);
        else if (usersTXs.length < 11) {
            paggedArray = new UserTX[](usersTXs.length);

            uint256 x;
            while (true) {
                paggedArray[x] = usersTXs[
                    usersTXs.length - 1 - x
                ];

                if (x == usersTXs.length - 1) break;

                unchecked {
                    x++;
                }
            }

            return (1, 1, paggedArray);
        }

        if (page == 0) page = 1;

        totalPages = usersTXs.length / 10;

        uint256 diffLength = usersTXs.length -
            (totalPages * 10);

        if (totalPages * 10 < usersTXs.length) totalPages++;
        if (page > totalPages) page = totalPages;
        currentPage = page;

        uint256 firstIndex;
        uint256 lastIndex;
        if (page == 1) {
            firstIndex = usersTXs.length - 1;
            lastIndex = firstIndex - 10;
        } else if (page == totalPages)
            firstIndex = diffLength == 0 ? firstIndex = 9 : diffLength - 1;
        else {
            firstIndex +=
                ((totalPages - page) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
            lastIndex +=
                ((totalPages - page - 1) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
        }

        paggedArray = new UserTX[]((firstIndex + 1) - lastIndex);

        uint256 i;
        while (true) {
            paggedArray[i] = usersTXs[firstIndex];

            if (firstIndex == lastIndex) break;
            unchecked {
                i++;
                firstIndex--;
            }
        }
    }
}
