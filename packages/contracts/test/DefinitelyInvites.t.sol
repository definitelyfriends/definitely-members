// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@def/DefinitelyInvites.sol";
import "@def/DefinitelyMemberships.sol";
import "@def/interfaces/IDefinitelyMemberships.sol";
import "./mocks/MockInvites.sol";

contract DefinitelyInvitesTest is Test {
    DefinitelyInvites private invites;
    DefinitelyMemberships private memberships;

    MockInvites private mockInvites;

    address private owner = mkaddr("owner");
    address private memberA = mkaddr("memberA");
    address private memberB = mkaddr("memberB");
    address private memberC = mkaddr("memberC");

    uint256 private inviteCooldown = 24 hours;

    function mkaddr(string memory name) public returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }

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

    function testInitsCorrectly() public {
        assertEq(invites.owner(), owner);
        assertEq(invites.inviteCooldown(), inviteCooldown);
    }

    function testSendClaimableInvite() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberB);

        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(invites.inviteAvailable(memberB), true);

        vm.prank(memberB);
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberB), 1);

        vm.warp(block.timestamp + inviteCooldown);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberC);

        assertEq(memberships.balanceOf(memberC), 0);
        assertEq(invites.inviteAvailable(memberC), true);

        vm.prank(memberC);
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberC), 1);
    }

    function testSendImmediateInvite() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.startPrank(memberA);

        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 1);

        vm.warp(block.timestamp + inviteCooldown);

        invites.sendImmediateInvite(memberC);
        assertEq(memberships.balanceOf(memberC), 1);

        vm.stopPrank();
    }

    function testCannotSendInvitesIfNotMember() public {
        assertEq(memberships.balanceOf(memberB), 0);

        vm.startPrank(memberA);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.NotDefMember.selector));
        invites.sendClaimableInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.NotDefMember.selector));
        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.stopPrank();
    }

    function testCannotSendClaimableInvitesTooQuickly() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.startPrank(memberA);

        invites.sendClaimableInvite(memberB);
        assertEq(invites.inviteAvailable(memberB), true);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.InviteOnCooldown.selector));
        invites.sendClaimableInvite(memberC);
        assertEq(invites.inviteAvailable(memberC), false);

        vm.stopPrank();
    }

    function testCannotSendImmediateInvitesTooQuickly() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 0);

        vm.startPrank(memberA);
        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 1);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.InviteOnCooldown.selector));
        invites.sendImmediateInvite(memberC);
        assertEq(memberships.balanceOf(memberC), 0);
        vm.stopPrank();
    }

    function testCannotInviteExistingMember() public {
        mockInvites.sendImmediateInvite(memberA);
        mockInvites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.balanceOf(memberB), 1);

        vm.startPrank(memberA);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.AlreadyDefMember.selector));
        invites.sendClaimableInvite(memberB);
        assertEq(invites.inviteAvailable(memberB), false);

        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.AlreadyDefMember.selector));
        invites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberB), 1);

        vm.stopPrank();
    }

    function testCannotClaimInviteIfOneIsNotAvailable() public {
        assertEq(memberships.balanceOf(memberB), 0);
        vm.prank(memberB);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.NoInviteToClaim.selector));
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberB), 0);
    }

    function testCannotClaimInviteIfAlreadyMember() public {
        mockInvites.sendImmediateInvite(memberA);
        mockInvites.sendImmediateInvite(memberB);
        assertEq(memberships.balanceOf(memberC), 0);

        vm.prank(memberA);
        invites.sendClaimableInvite(memberC);

        vm.prank(memberB);
        invites.sendImmediateInvite(memberC);
        assertEq(memberships.balanceOf(memberC), 1);

        vm.prank(memberC);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyInvites.AlreadyDefMember.selector));
        invites.claimInvite();
        assertEq(memberships.balanceOf(memberC), 1);
    }
}
