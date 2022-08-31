//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {IDefinitelyMemberships} from "src/interfaces/IDefinitelyMemberships.sol";

contract MockRevoke {
    IDefinitelyMemberships public definitelyMemberships;

    constructor(address definitelyMemberships_) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
    }

    function revoke(uint256 id, bool addToDenyList) external {
        IDefinitelyMemberships(definitelyMemberships).revokeMembership(id, addToDenyList);
    }
}
