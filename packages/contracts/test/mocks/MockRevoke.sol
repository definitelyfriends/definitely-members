//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "def/interfaces/IDefinitelyMemberships.sol";

contract MockRevoke {
    IDefinitelyMemberships public definitelyMemberships;

    constructor(address definitelyMemberships_) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
    }

    function revoke(uint256 id, bool addToDenyList_) external {
        IDefinitelyMemberships(definitelyMemberships).revokeMembership(id, addToDenyList_);
    }

    function addToDenyList(address account) external {
        IDefinitelyMemberships(definitelyMemberships).addAddressToDenyList(account);
    }

    function removeFromDenyList(address account) external {
        IDefinitelyMemberships(definitelyMemberships).removeAddressFromDenyList(account);
    }
}
