// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "def/DefinitelyInvites.sol";
import "def/DefinitelyMemberships.sol";
import "def/interfaces/IDefinitelyMemberships.sol";
import "./mocks/MockInvites.sol";

contract DefinitelyInvitesTest is Test {
    DefinitelyInvites private invites;
    DefinitelyMemberships private memberships;

    MockInvites private mockInvites;

    address private owner = makeAddr("owner");
    address private memberA = makeAddr("memberA");
    address private memberB = makeAddr("memberB");
    address private memberC = makeAddr("memberC");

    uint256 private inviteCooldown = 24 hours;

    event InviteCooldownUpdated(uint256 indexed cooldown);
    event MemberInvited(address indexed invited, address indexed invitedBy);
    event InviteClaimed(address indexed invited);

    function setUp() public {
        memberships = new DefinitelyMemberships(owner);
        invites = new DefinitelyInvites(owner, address(memberships), inviteCooldown);
        mockInvites = new MockInvites(address(memberships));

        vm.startPrank(owner);
        memberships.addMembershipIssuingContract(address(invites));
        memberships.addMembershipIssuingContract(address(mockInvites));
        vm.stopPrank();

        // Set a fixed date before every test, otherwise block.timestamp will be 1
        // which won't happen IRL, but will cause cooldown conditions to break
        vm.warp(1649286000);
    }

    function test_SetUp() public {
        assertEq(invites.owner(), owner);
        assertEq(invites.inviteCooldown(), inviteCooldown);
    }

    function test_SendClaimableInvite() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.expectEmit(true, true, true, true);
        emit MemberInvited(memberB, memberA);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);

        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(invites.inviteAvailable(memberB), true);
    }

    function test_SendClaimableInvite_AfterCooldown() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(invites.inviteAvailable(memberB), true);

        vm.warp(block.timestamp + inviteCooldown);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberC);
        assertEq(invites.inviteAvailable(memberC), true);
    }

    function test_SendClaimableInvite_RevertIf_NotDefMember() public {
        assertEq(memberships.balanceOf(memberA), 0);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.NotDefMember.selector);
        invites.sendClaimableInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 0);
    }

    function test_SendClaimableInvite_RevertIf_AlreadyDefMember() public {
        mockInvites.sendImmediateInvite(memberA);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);
        assertEq(invites.inviteAvailable(memberB), true);

        vm.prank(memberB);
        invites.claimInvite();

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.AlreadyDefMember.selector);
        invites.sendClaimableInvite(memberB);
    }

    function test_SendClaimableInvite_RevertIf_InviteOnCooldown() public {
        mockInvites.sendImmediateInvite(memberA);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);
        assertEq(invites.inviteAvailable(memberB), true);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.InviteOnCooldown.selector);
        invites.sendClaimableInvite(memberC);
        assertEq(invites.inviteAvailable(memberC), false);
    }

    function test_SendImmediateInvite() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.prank(memberA);
        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 1);
    }

    function test_SendImmediateInvite_AfterCooldown() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.prank(memberA);
        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 1);

        vm.warp(block.timestamp + inviteCooldown);

        vm.prank(memberA);
        invites.sendImmediateInvite(memberC);
        assertEq(memberships.balanceOf(memberC), 1);
    }

    function test_SendImmediateInvite_RevertIf_NotDefMember() public {
        assertEq(memberships.balanceOf(memberA), 0);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.NotDefMember.selector);
        invites.sendImmediateInvite(memberB);
    }

    function test_SendImmediateInvite_RevertIf_AlreadyDefMember() public {
        mockInvites.sendImmediateInvite(memberA);

        vm.prank(memberA);
        invites.sendImmediateInvite(memberB);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.AlreadyDefMember.selector);
        invites.sendImmediateInvite(memberB);
    }

    function test_SendImmediateInvite_RevertIf_InviteOnCooldown() public {
        mockInvites.sendImmediateInvite(memberA);

        vm.prank(memberA);
        invites.sendImmediateInvite(memberB);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyInvites.InviteOnCooldown.selector);
        invites.sendImmediateInvite(memberC);
    }

    function test_ClaimInvite() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);

        vm.expectEmit(true, true, true, true);
        emit InviteClaimed(memberB);

        vm.prank(memberB);
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberB), 1);
    }

    function test_ClaimInvite_RevertIf_NoInviteToClaim() public {
        assertEq(memberships.balanceOf(memberB), 0);
        vm.prank(memberB);
        vm.expectRevert(DefinitelyInvites.NoInviteToClaim.selector);
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberB), 0);
    }

    function test_ClaimInvite_RevertIf_AlreadyMember() public {
        mockInvites.sendImmediateInvite(memberA);
        mockInvites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberC), 0);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberC);

        vm.prank(memberB);
        invites.sendImmediateInvite(memberC);
        assertEq(memberships.balanceOf(memberC), 1);

        vm.prank(memberC);
        vm.expectRevert(DefinitelyMemberships.AlreadyDefMember.selector);
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberC), 1);
    }

    function test_SetInviteCooldown() public {
        assertEq(invites.inviteCooldown(), inviteCooldown);

        vm.expectEmit(true, true, true, true);
        emit InviteCooldownUpdated(1 hours);

        vm.prank(owner);
        invites.setInviteCooldown(1 hours);
        assertEq(invites.inviteCooldown(), 1 hours);
    }
}
