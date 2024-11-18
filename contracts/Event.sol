//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

import {IEventFactory} from "./interfaces/IEventFactory.sol";
import {Clone} from "./libs/Clone.sol";

contract Event is Clone {
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
}
