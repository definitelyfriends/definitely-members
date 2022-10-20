// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "def/DefinitelyRevoke.sol";
import "def/DefinitelyMemberships.sol";
import "def/interfaces/IDefinitelyMemberships.sol";
import "./mocks/MockInvites.sol";

contract DefinitelyRevokeTest is Test {
    DefinitelyRevoke private invites;
    DefinitelyMemberships private memberships;

    MockInvites private mockInvites;

    address private owner = makeAddr("owner");
    address private memberA = makeAddr("memberA");
    address private memberB = makeAddr("memberB");
    address private memberC = makeAddr("memberC");

    uint64 private minQuorum = 8;
    uint64 private maxVotes = 12;

    function setUp() public {
        // memberships = new DefinitelyMemberships(owner);
        // invites = new DefinitelyRevoke(owner, address(memberships), minQuorum, maxVotes);
        // mockInvites = new MockInvites(address(memberships));
        // vm.startPrank(owner);
        // memberships.addMembershipIssuingContract(address(invites));
        // memberships.addMembershipIssuingContract(address(mockInvites));
        // vm.stopPrank();
        // // Set a fixed date before every test, otherwise block.timestamp will be 1
        // // which won't happen IRL, but will cause cooldown conditions to break
        // vm.warp(1649286000);
    }

    // function testInitsCorrectly() public {
    //     assertEq(invites.owner(), owner);
    // }
}
