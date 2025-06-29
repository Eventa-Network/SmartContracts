//  SPDX-License-Identifier: -- Ewana --
pragma solidity 0.8.25;

import {IEventaFactory} from "./interfaces/IEventaFactory.sol";
import {Clone} from "./libs/Clone.sol";

contract Eventa is Clone {
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

    function EventaFactory() public pure returns (IEventaFactory) {
        return IEventaFactory(_getArgAddress(23));
    }

    uint32 public UTCstartTime;
    uint32 public UTCendTime;
    uint128 public Price;
    uint128 public TotalSupply;
    bytes32 public LocationRefHash;
    bytes32 PublicDescRefHash;
    bytes32 PrivateDescRefHash;
    string public Name;
    string[3] public Tags;

    modifier onlyCreator() {
        require(tx.origin == Creator(), "Eventa: ONLY_CREATOR");

        _;
    }

    function init(
        uint32 utcStartTime,
        uint32 utcEndTime,
        uint128 price,
        uint128 totalSupply,
        bytes32 locationRefHash,
        bytes32 publicDescRefHash,
        bytes32 privateDescRefHash,
        string calldata name,
        string[3] calldata tags
    ) external {
        require(
            msg.sender == address(EventaFactory()),
            "Eventa: ONLY_FACTORY"
        );

        Price = price;
        TotalSupply = totalSupply;
        LocationRefHash = locationRefHash;
        PublicDescRefHash = publicDescRefHash;
        PrivateDescRefHash = privateDescRefHash;

        (UTCstartTime, UTCendTime) = (utcStartTime, utcEndTime);

        Name = name;

        Tags[0] = tags[0];
        Tags[1] = tags[1];
        Tags[2] = tags[2];
    }

    function changeUTCtime(bytes calldata utcTime) external onlyCreator {
        (UTCstartTime, UTCendTime) = abi.decode(utcTime, (uint32, uint32));
        require(
            UTCstartTime > block.timestamp && UTCendTime > block.timestamp,
            "Eventa: ONLY_BIGGER_TS"
        );
        require(UTCstartTime <= UTCendTime, "Eventa: CHECK_END_TIME");
    }

    function changePrice(uint128 newPrice) external onlyCreator {
        if (Price == 0 || (newPrice == 0 && Price != 0))
            revert("Eventa: CANT_CHANGE_PRICE");
        Price = newPrice;
    }

    function changeTotalSupply(uint128 newTotalSupply) external onlyCreator {
        require(newTotalSupply == 0, "Eventa: TOTAL_SUPPLY_CANT_BE_ZERO");

        require(Type() != 1, "Eventa: CANT_CHANGE_APPROVAL_EVENT");

        TotalSupply = newTotalSupply;
    }

    //!TODO: Needs to check signature
    // function changeLocationRefHash() external onlyCreator {}
    // function changePublicDescRefHash() external onlyCreator {}
    // function changePrivateDescRefHash() external onlyCreator {}

    function changeName(string calldata newName) external onlyCreator {
        require(
            bytes(newName).length != 0 && bytes(newName).length < 33,
            "Eventa: CHECK_LENGTH"
        );

        Name = newName;
    }

    function changeTags(string[3] calldata newTags) external onlyCreator {
        Tags[0] = newTags[0];
        Tags[1] = newTags[1];
        Tags[2] = newTags[2];
    }
}
