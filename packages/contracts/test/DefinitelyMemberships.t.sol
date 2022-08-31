// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@def/DefinitelyMemberships.sol";
import "@def/DefinitelyMetadata.sol";
import "@def/interfaces/IDefinitelyMemberships.sol";
import "./mocks/MockInvites.sol";
import "./mocks/MockRevoke.sol";
import "./mocks/MockTransfer.sol";

contract DefinitelyMembershipsTest is Test {
    DefinitelyMemberships private memberships;
    DefinitelyMetadata private metadata;

    MockInvites private mockInvites;
    MockRevoke private mockRevoke;
    MockTransfer private mockTransfer;

    address private owner = vm.addr(uint256(keccak256(abi.encodePacked("owner"))));
    address private memberA = vm.addr(uint256(keccak256(abi.encodePacked("memberA"))));
    address private memberB = vm.addr(uint256(keccak256(abi.encodePacked("memberB"))));
    address private memberC = vm.addr(uint256(keccak256(abi.encodePacked("memberC"))));

    function setUp() public {
        metadata = new DefinitelyMetadata(owner, "ipfs://baseHash/");
        memberships = new DefinitelyMemberships(owner, address(metadata));

        mockInvites = new MockInvites(address(memberships));
        mockRevoke = new MockRevoke(address(memberships));
        mockTransfer = new MockTransfer(address(memberships));

        vm.startPrank(owner);
        memberships.addMembershipIssuingContract(address(mockInvites));
        memberships.addMembershipRevokingContract(address(mockRevoke));
        memberships.addMembershipTransferContract(address(mockTransfer));
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(memberships.owner(), owner);
    }

    function testAllowedContractsAdminFunctions() public {
        MockInvites invites = new MockInvites(address(memberships));
        MockRevoke revoke = new MockRevoke(address(memberships));
        MockTransfer transfer = new MockTransfer(address(memberships));

        // Should fail if not the owner
        vm.expectRevert("UNAUTHORIZED");
        memberships.addMembershipIssuingContract(address(invites));

        vm.expectRevert("UNAUTHORIZED");
        memberships.addMembershipRevokingContract(address(revoke));

        vm.expectRevert("UNAUTHORIZED");
        memberships.addMembershipTransferContract(address(transfer));

        vm.startPrank(owner);
        memberships.addMembershipIssuingContract(address(invites));
        assertEq(memberships.allowedMembershipIssuingContracts(address(invites)), true);
        memberships.removeMembershipIssuingContract(address(invites));
        assertEq(memberships.allowedMembershipIssuingContracts(address(invites)), false);

        memberships.addMembershipRevokingContract(address(revoke));
        assertEq(memberships.allowedMembershipRevokingContracts(address(revoke)), true);
        memberships.removeMembershipRevokingContract(address(revoke));
        assertEq(memberships.allowedMembershipRevokingContracts(address(revoke)), false);

        memberships.addMembershipTransferContract(address(transfer));
        assertEq(memberships.allowedMembershipTransferContracts(address(transfer)), true);
        memberships.removeMembershipTransferContract(address(transfer));
        assertEq(memberships.allowedMembershipTransferContracts(address(transfer)), false);
        vm.stopPrank();
    }

    function testIssuingMemberships() public {
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
    }

    function testRevokingMemberships() public {
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImediateInvite(memberA);

        assertEq(memberships.balanceOf(memberB), 0);
        mockInvites.sendImediateInvite(memberB);

        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.ownerOf(1), memberA);

        mockRevoke.revoke(1, false);
        assertEq(memberships.balanceOf(memberA), 0);
        assertEq(memberships.isOnDenyList(memberA), false);

        mockRevoke.revoke(2, true);
        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(memberships.isOnDenyList(memberB), true);
    }

    function testCannotTransferMemberships() public {
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.prank(memberA);
        vm.expectRevert(
            abi.encodeWithSelector(DefinitelyMemberships.NotAuthorizedToTransferMembership.selector)
        );
        memberships.transferFrom(memberA, memberB, 1);
    }
}
