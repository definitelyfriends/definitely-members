//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "def/interfaces/IDefinitelyMemberships.sol";

contract MockInvites {
    IDefinitelyMemberships public definitelyMemberships;
    mapping(address => bool) public inviteAvailable;
    error NoInviteToClaim();

    constructor(address definitelyMemberships_) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
    }

    function sendClaimableInvite(address to) external {
        inviteAvailable[to] = true;
    }

    function sendImmediateInvite(address to) external {
        definitelyMemberships.issueMembership(to);
    }

    function claimInvite() external {
        if (inviteAvailable[msg.sender]) revert NoInviteToClaim();
        definitelyMemberships.issueMembership(msg.sender);
    }
}
