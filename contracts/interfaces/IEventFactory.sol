//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

// [true,"1","2","5","1742465494","1742475494","0xA390E1dB7589b809ED3B01bE96fC8168DaCD15c0","1000000000000000000","1000","0xdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7","0xdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7","0xdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7","Test Event",["Crypto","DevCon","ETH"]]

enum Transferable {
    True,
    False,
    Conditional
}

struct EventInfo {
    bool Virtual;
    Transferable Transferable;
    uint8 Type; // Public Event, Approval Event, Private Event and more for future...
    uint8 Limit;
    uint32 UTCstartTime;
    uint32 UTCendTime;
    address Creator;
    uint128 Price;
    uint128 TotalSupply;
    bytes32 LocationRefHash;
    bytes32 PublicDescRefHash;
    bytes32 PrivateDescRefHash;
    string Name;
    string[3] Tags;
}

interface IEventFactory {
    event EventCreated(
        EventInfo eventInfo,
        address eventAddress,
        uint256 usedNonce
    );

    function createEvent(EventInfo calldata eventInfo, bytes calldata signature)
        external;

    function getPreAddressAndNonce(EventInfo calldata eventInfo)
        external
        view
        returns (address, uint256);
}
