//  SPDX-License-Identifier: -- STAMP --
pragma solidity 0.8.25;

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
    uint64 UTCtime;
    address Creator;
    uint128 Price;
    uint128 TotalSupply;
    bytes32 LocationHash;
    string Name;
    string Description;
    string[] Tags;
}

interface IEventFactory {
    event EventCreated(EventInfo eventInfo, address eventAddress);

    function createEvent(
        EventInfo calldata eventInfo,
        bytes calldata signature
    ) external;
}
