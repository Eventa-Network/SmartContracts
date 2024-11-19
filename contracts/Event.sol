//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IEventFactory} from "./interfaces/IEventFactory.sol";
import {Clone} from "./libs/Clone.sol";

contract Event is Clone {
    error CantChangePrice();

    function Virtual() public pure returns (bool) {
        return _getArgUint8(0) == 1;
    }

    function Transferable() public pure returns (uint8) {
        return _getArgUint8(1);
    }

    function Type() public pure returns (uint8) {
        return _getArgUint8(2);
    }

    function Creator() public pure returns (address) {
        return _getArgAddress(3);
    }

    function EventFactory() public pure returns (IEventFactory) {
        return IEventFactory(_getArgAddress(23));
    }

    uint64 public UTCtime;
    uint128 public Price;
    uint128 public TotalSupply;
    bytes32 public LocationHash;
    string public Name;
    string public Description;
    string[] public Tags;

    modifier onlyCreator() {
        require(tx.origin == Creator(), "EVENT: ONLY_CREATOR");

        _;
    }

    function init(
        uint64 utcTime,
        uint128 price,
        uint128 totalSupply,
        bytes32 locationHash,
        string calldata name,
        string calldata description,
        string[] calldata tags
    ) external {
        require(msg.sender == address(EventFactory()), "EVENT: ONLY_FACTORY");

        UTCtime = utcTime;
        Price = price;
        TotalSupply = totalSupply;
        LocationHash = locationHash;
        Name = name;
        Description = description;

        uint256 tagsLength = tags.length;
        for (uint256 i; i < tagsLength; ) {
            Tags[i] = tags[i];

            unchecked {
                i++;
            }
        }
    }

    function changeUTCtime(uint64 utcTime) external onlyCreator {
        require(utcTime > block.timestamp, "EVENT: ONLY_BIGGER_TS");

        UTCtime = utcTime;
    }

    function changePrice(uint128 newPrice) external onlyCreator {
        if (Price == 0 || (newPrice == 0 && Price != 0))
            revert CantChangePrice();

        Price = newPrice;
    }

    function changeTotalSupply(uint128 newTotalSupply) external onlyCreator {
        require(newTotalSupply == 0, "EVENT: TOTAL_SUPPLY_CANT_BE_ZERO");

        require(Type() != 1, "EVENT: CANT_CHANGE_APPROVAL_EVENT");

        // IStamper(STAMPER).CheckCurrentSupply(address(this), SigHash);

        TotalSupply = newTotalSupply;
    }

    //!TODO: Needs to check signature 
    // function changeLocationHash() external onlyCreator {}

    function changeName(string calldata newName) external onlyCreator {
        require(
            bytes(newName).length != 0 && bytes(newName).length < 33,
            "EVENT: CHECK_LENGTH"
        );

        Name = newName;
    }

    function changeDesc(string calldata newDesc) external onlyCreator {
        require(
            bytes(newDesc).length != 0 && bytes(newDesc).length < 33,
            "EVENT: CHECK_LENGTH"
        );

        Description = newDesc;
    }

    function changeTags(string[] calldata newTags) external onlyCreator {
        require(newTags.length < 4 && newTags.length != 0);

        uint256 tagsLength = newTags.length;
        delete Tags;
        for (uint256 i; i < tagsLength; ) {
            require(bytes(newTags[i]).length < 33, "EVENT: CHECK_LENGTH");

            Tags[i] = newTags[i];
        }
    }
}
