// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@def/DefinitelyMemberships.sol";
import "@def/interfaces/IDefinitelyMemberships.sol";
import "@def/interfaces/IDefinitelyMetadata.sol";
import "./mocks/MockInvites.sol";
import "./mocks/MockRevoke.sol";
import "./mocks/MockTransfer.sol";
import "./mocks/MockMetadata.sol";

contract CustomMetadata is IDefinitelyMetadata {
    function tokenURI(uint256 id) external pure returns (string memory) {
        return string.concat("ipfs://CUSTOM_HASH/", Strings.toString(id));
    }
}

contract DefinitelyMembershipsTest is Test {
    DefinitelyMemberships private memberships;

    MockInvites private mockInvites;
    MockRevoke private mockRevoke;
    MockTransfer private mockTransfer;
    MockMetadata private mockMetadata;

    address private owner = mkaddr("owner");
    address private memberA = mkaddr("memberA");
    address private memberB = mkaddr("memberB");
    address private memberC = mkaddr("memberC");

    function mkaddr(string memory name) public returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }

    function setUp() public {
        memberships = new DefinitelyMemberships(owner);

        mockInvites = new MockInvites(address(memberships));
        mockRevoke = new MockRevoke(address(memberships));
        mockTransfer = new MockTransfer(address(memberships));
        mockMetadata = new MockMetadata("ipfs://BASE_HASH/");

        vm.startPrank(owner);
        memberships.addMembershipIssuingContract(address(mockInvites));
        memberships.addMembershipRevokingContract(address(mockRevoke));
        memberships.addMembershipTransferContract(address(mockTransfer));
        memberships.setDefaultMetadata(address(mockMetadata));
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

        assertEq(memberships.defaultMetadata(), address(mockMetadata));
        CustomMetadata customMetadata = new CustomMetadata();
        memberships.setDefaultMetadata(address(customMetadata));
        assertEq(memberships.defaultMetadata(), address(customMetadata));
        vm.stopPrank();
    }

    function testIssuingMemberships() public {
        // Can issue a membership token
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
    }

    function testCannotIssueMembershipToExistingMember() public {
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyMemberships.AlreadyDefMember.selector));
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
    }

    function testCannotIusseMembershipToDenyListAccount() public {
        mockRevoke.addToDenyList(memberB);
        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(memberships.isOnDenyList(memberB), true);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyMemberships.OnDenyList.selector));
        mockInvites.sendImediateInvite(memberB);
    }

    function testCannotIssueMembershipIfNotFromApprovedContract() public {
        vm.expectRevert(
            abi.encodeWithSelector(DefinitelyMemberships.NotAuthorizedToIssueMembership.selector)
        );
        memberships.issueMembership(memberC);
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

    function testAddAddressToDenyList() public {
        mockRevoke.addToDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), true);
    }

    function testCannotAddAddressToDenyListIfNotFromApprovedContract() public {
        vm.expectRevert(
            abi.encodeWithSelector(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector)
        );
        memberships.addAddressToDenyList(memberA);
    }

    function testCannotRemoveAddressFromDenyListIfNotFromApprovedContract() public {
        vm.expectRevert(
            abi.encodeWithSelector(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector)
        );
        memberships.removeAddressFromDenyList(memberA);
    }

    function testRemoveAddressToDenyList() public {
        mockRevoke.addToDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), true);
        mockRevoke.removeFromDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), false);
    }

    function testTransferMembership() public {
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);
        mockTransfer.transfer(1, memberB);
        assertEq(memberships.ownerOf(1), memberB);
        assertEq(memberships.balanceOf(memberA), 0);
    }

    function testCannotTransferMembership() public {
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.prank(memberA);
        vm.expectRevert(
            abi.encodeWithSelector(DefinitelyMemberships.NotAuthorizedToTransferMembership.selector)
        );
        memberships.transferFrom(memberA, memberB, 1);
    }

    function testOverrideMetadataForToken() public {
        CustomMetadata customMetadata = new CustomMetadata();
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.tokenURI(1), "ipfs://BASE_HASH/1");
        vm.prank(memberA);
        memberships.overrideMetadataForToken(1, address(customMetadata));
        assertEq(memberships.tokenURI(1), "ipfs://CUSTOM_HASH/1");
    }

    function testResetMetadataForToken() public {
        CustomMetadata customMetadata = new CustomMetadata();
        mockInvites.sendImediateInvite(memberA);
        vm.startPrank(memberA);
        memberships.overrideMetadataForToken(1, address(customMetadata));
        memberships.resetMetadataForToken(1);
        vm.stopPrank();
        assertEq(memberships.tokenURI(1), "ipfs://BASE_HASH/1");
    }

    function testBurn() public {
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        vm.prank(memberA);
        memberships.burn(1);
    }

    function testCannotBurnTokenYouDoNotOwn() public {
        mockInvites.sendImediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        vm.prank(memberB);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyMemberships.NotOwnerOfToken.selector));
        memberships.burn(1);
    }
}
