//  SPDX-License-Identifier: -- Ewana --
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUSDTswapper} from "./interfaces/IUSDTswapper.sol";

contract EwanaChargeStation {
    struct UserTX {
        address user;
        address platform;
        address token;
        uint256 tokenAmount;
        uint256 amountInUSDT;
        bytes32 txID;
    }

    IERC20 public immutable USDT;
    IUSDTswapper public immutable USDT_SWAPPER;

    UserTX[] public usersTXs;
    mapping(address => uint256) public platformUSDTbalance;
    mapping(address => uint256) public userNonce;

    event Charged(
        address indexed chargedFor,
        uint256 indexed amountInUSDT,
        address indexed platform,
        address charger
    );

    event USDTtransferedByPlatform(
        address indexed to,
        uint256 indexed amountInUSDT,
        address indexed platform,
        uint256 currentPlatformUSDTbalance
    );

    constructor(address usdt, address swapper) {
        require(
            usdt != address(0) && swapper != address(0),
            "EwanaChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        USDT = IERC20(usdt);
        USDT_SWAPPER = IUSDTswapper(swapper);
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
            "EwanaChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        require(amount != 0, "EwanaChargeStation: ZERO_AMOUNT_PROVIDED");
        require(
            platform != address(0),
            "EwanaChargeStation: ZERO_ADDRESS_PROVIDED"
        );
        if (for_ == address(0)) for_ = msg.sender;

        uint256 amountInUSDT;
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (token == address(USDT)) {
            amountInUSDT = amount;

            emit Charged(for_, amountInUSDT, platform, msg.sender);
        } else {
            // TODO: SWAP INTO USDT
            USDT_SWAPPER.isSwappable(token, amount, helpPath);
            amountInUSDT = USDT_SWAPPER.swapIntoUSDT(token, amount, helpPath);

            emit Charged(for_, amountInUSDT, platform, msg.sender);
        }

        platformUSDTbalance[platform] += amountInUSDT;
        usersTXs.push(
            UserTX(
                for_,
                platform,
                token,
                amount,
                amountInUSDT,
                (keccak256(abi.encodePacked(for_, userNonce[for_])))
            )
        );
        userNonce[for_]++;
    }

    function transferUSDT(address to, uint256 amount) external {
        require(
            platformUSDTbalance[msg.sender] >= amount,
            "EwanaChargeStation: INSUFFICIENT_USDT_BALANCE"
        );

        unchecked {
            platformUSDTbalance[msg.sender] -= amount;
        }

        USDT.transfer(to, amount);

        emit USDTtransferedByPlatform(
            to,
            amount,
            msg.sender,
            platformUSDTbalance[msg.sender]
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
