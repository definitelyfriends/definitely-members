//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "def/interfaces/IDefinitelyMemberships.sol";

contract MockTransfer {
    IDefinitelyMemberships public definitelyMemberships;

    constructor(address definitelyMemberships_) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
    }

    function transfer(uint256 id, address to) external {
        IDefinitelyMemberships(definitelyMemberships).transferMembership(id, to);
    }
}
