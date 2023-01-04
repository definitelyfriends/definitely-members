// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "def/DefinitelyMemberships.sol";
import "def/interfaces/IDefinitelyMemberships.sol";
import "def/interfaces/IDefinitelyMetadata.sol";
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

    address private owner = makeAddr("owner");
    address private memberA = makeAddr("memberA");
    address private memberB = makeAddr("memberB");
    address private memberC = makeAddr("memberC");

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event MembershipIssuingContractAdded(address indexed contractAddress);
    event MembershipIssuingContractRemoved(address indexed contractAddress);
    event MembershipIssued(uint256 indexed id, address indexed newOwner);
    event MembershipRevokingContractAdded(address indexed contractAddress);
    event MembershipRevokingContractRemoved(address indexed contractAddress);
    event MembershipRevoked(uint256 indexed id, address indexed prevOwner);
    event AddedToDenyList(address indexed account);
    event RemovedFromDenyList(address indexed account);
    event MembershipTransferContractAdded(address indexed contractAddress);
    event MembershipTransferContractRemoved(address indexed contractAddress);
    event DefaultMetadataUpdated(address indexed metadata);
    event MetadataOverridden(uint256 indexed id, address indexed metadata);
    event MetadataResetToDefault(uint256 indexed id);

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

    function test_Owner() public {
        assertEq(memberships.owner(), owner);
    }

    function test_AllowedContractsAdminFunctions() public {
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

        vm.expectEmit(true, true, true, true);
        emit MembershipIssuingContractAdded(address(invites));

        memberships.addMembershipIssuingContract(address(invites));
        assertEq(memberships.allowedMembershipIssuingContract(address(invites)), true);

        vm.expectEmit(true, true, true, true);
        emit MembershipIssuingContractRemoved(address(invites));

        memberships.removeMembershipIssuingContract(address(invites));
        assertEq(memberships.allowedMembershipIssuingContract(address(invites)), false);

        vm.expectEmit(true, true, true, true);
        emit MembershipRevokingContractAdded(address(revoke));

        memberships.addMembershipRevokingContract(address(revoke));
        assertEq(memberships.allowedMembershipRevokingContract(address(revoke)), true);

        vm.expectEmit(true, true, true, true);
        emit MembershipRevokingContractRemoved(address(revoke));

        memberships.removeMembershipRevokingContract(address(revoke));
        assertEq(memberships.allowedMembershipRevokingContract(address(revoke)), false);

        vm.expectEmit(true, true, true, true);
        emit MembershipTransferContractAdded(address(transfer));

        memberships.addMembershipTransferContract(address(transfer));
        assertEq(memberships.allowedMembershipTransferContract(address(transfer)), true);

        vm.expectEmit(true, true, true, true);
        emit MembershipTransferContractRemoved(address(transfer));

        memberships.removeMembershipTransferContract(address(transfer));
        assertEq(memberships.allowedMembershipTransferContract(address(transfer)), false);

        assertEq(memberships.defaultMetadataAddress(), address(mockMetadata));

        CustomMetadata customMetadata = new CustomMetadata();

        vm.expectEmit(true, true, true, true);
        emit DefaultMetadataUpdated(address(customMetadata));

        memberships.setDefaultMetadata(address(customMetadata));
        assertEq(memberships.defaultMetadataAddress(), address(customMetadata));
        vm.stopPrank();
    }

    function test_IssueMembership() public {
        assertEq(memberships.balanceOf(memberA), 0);

        vm.expectEmit(true, true, true, true);
        emit MembershipIssued(1, memberA);

        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
    }

    function test_IssueMembership_Fuzz(address member) public {
        vm.assume(member != address(0));
        assertEq(memberships.balanceOf(member), 0);

        vm.expectEmit(true, true, true, true);
        emit MembershipIssued(1, member);

        mockInvites.sendImmediateInvite(member);
        assertEq(memberships.balanceOf(member), 1);
    }

    function test_IssueMembership_RevertIf_AlreadyDefMember() public {
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyMemberships.AlreadyDefMember.selector));
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
    }

    function test_IssueMembership_RevertIf_OnDenyList() public {
        mockRevoke.addToDenyList(memberB);
        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(memberships.isOnDenyList(memberB), true);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyMemberships.OnDenyList.selector));
        mockInvites.sendImmediateInvite(memberB);
    }

    function test_IssueMembership_RevertIf_NotAuthorizedToIssueMembership() public {
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToIssueMembership.selector);
        memberships.issueMembership(memberC);
    }

    function test_IssueMembership_RevertIf_NotAuthorizedToIssueMembership_Fuzz(address caller)
        public
    {
        vm.assume(caller != address(mockInvites));
        vm.prank(caller);
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToIssueMembership.selector);
        memberships.issueMembership(memberA);
    }

    function test_RevokeMembership() public {
        assertEq(memberships.balanceOf(memberA), 0);
        mockInvites.sendImmediateInvite(memberA);

        assertEq(memberships.balanceOf(memberB), 0);
        mockInvites.sendImmediateInvite(memberB);

        assertEq(memberships.balanceOf(memberA), 1);
        assertEq(memberships.ownerOf(1), memberA);

        vm.expectEmit(true, true, true, true);
        emit MembershipRevoked(1, memberA);

        mockRevoke.revoke(1, false);
        assertEq(memberships.balanceOf(memberA), 0);
        assertEq(memberships.isOnDenyList(memberA), false);

        vm.expectEmit(true, true, true, true);
        emit AddedToDenyList(memberB);

        vm.expectEmit(true, true, true, true);
        emit MembershipRevoked(2, memberB);

        mockRevoke.revoke(2, true);
        assertEq(memberships.balanceOf(memberB), 0);
        assertEq(memberships.isOnDenyList(memberB), true);
    }

    function test_RevokeMembership_Fuzz(address member) public {
        vm.assume(member != address(0));

        assertEq(memberships.balanceOf(member), 0);
        mockInvites.sendImmediateInvite(member);

        assertEq(memberships.balanceOf(member), 1);
        assertEq(memberships.ownerOf(1), member);

        mockRevoke.revoke(1, false);
        assertEq(memberships.balanceOf(member), 0);
        assertEq(memberships.isOnDenyList(member), false);
    }

    function test_AddAddressToDenyList() public {
        vm.expectEmit(true, true, true, true);
        emit AddedToDenyList(memberA);

        mockRevoke.addToDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), true);
    }

    function test_AddAddressToDenyList_Fuzz(address member) public {
        mockRevoke.addToDenyList(member);
        assertEq(memberships.isOnDenyList(member), true);
    }

    function test_AddAddressToDenyList_RevertIf_NotAuthorizedToRevokeMembership() public {
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector);
        memberships.addAddressToDenyList(memberA);
    }

    function test_AddAddressToDenyList_RevertIf_NotAuthorizedToRevokeMembership_Fuzz(address caller)
        public
    {
        vm.assume(caller != address(mockRevoke));
        vm.prank(caller);
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector);
        memberships.addAddressToDenyList(memberA);
    }

    function test_RemoveAddressFromDenyList() public {
        mockRevoke.addToDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), true);

        vm.expectEmit(true, true, true, true);
        emit RemovedFromDenyList(memberA);

        mockRevoke.removeFromDenyList(memberA);
        assertEq(memberships.isOnDenyList(memberA), false);
    }

    function test_RemoveAddressFromDenyList_RevertIf_NotAuthorizedToRevokeMembership() public {
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector);
        memberships.removeAddressFromDenyList(memberA);
    }

    function test_RemoveAddressFromDenyList_RevertIf_NotAuthorizedToRevokeMembership_Fuzz(
        address caller
    ) public {
        vm.assume(caller != address(mockRevoke));
        vm.prank(caller);
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToRevokeMembership.selector);
        memberships.removeAddressFromDenyList(memberA);
    }

    function test_TransferMembership() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.expectEmit(true, true, true, true);
        emit Transfer(memberA, memberB, 1);

        vm.prank(address(mockTransfer));
        memberships.transferMembership(1, memberB);
        assertEq(memberships.ownerOf(1), memberB);
        assertEq(memberships.balanceOf(memberA), 0);
    }

    function test_TransferMembership_RevertIf_CannotTransferToZeroAddress() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.prank(address(mockTransfer));
        vm.expectRevert(DefinitelyMemberships.CannotTransferToZeroAddress.selector);
        memberships.transferMembership(1, address(0));
    }

    function test_TransferFrom() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.expectEmit(true, true, true, true);
        emit Transfer(memberA, memberB, 1);

        mockTransfer.transfer(1, memberB);
        assertEq(memberships.ownerOf(1), memberB);
        assertEq(memberships.balanceOf(memberA), 0);
    }

    function test_TransferFrom_RevertIf_NotAuthorizedToTransferMembership() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.prank(memberA);
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToTransferMembership.selector);
        memberships.transferFrom(memberA, memberB, 1);
    }

    function test_TransferFrom_RevertIf_NotAuthorizedToTransferMembership_Fuzz(address caller)
        public
    {
        vm.assume(caller != address(mockTransfer));

        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.ownerOf(1), memberA);

        vm.prank(caller);
        vm.expectRevert(DefinitelyMemberships.NotAuthorizedToTransferMembership.selector);
        memberships.transferFrom(memberA, memberB, 1);
    }

    function test_OverrideMetadataForToken() public {
        CustomMetadata customMetadata = new CustomMetadata();
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.tokenURI(1), "ipfs://BASE_HASH/1");

        vm.expectEmit(true, true, true, true);
        emit MetadataOverridden(1, address(customMetadata));

        vm.prank(memberA);
        memberships.overrideMetadataForToken(1, address(customMetadata));
        assertEq(memberships.tokenURI(1), "ipfs://CUSTOM_HASH/1");
    }

    function test_ResetMetadataForToken() public {
        CustomMetadata customMetadata = new CustomMetadata();
        mockInvites.sendImmediateInvite(memberA);

        vm.prank(memberA);
        memberships.overrideMetadataForToken(1, address(customMetadata));

        vm.expectEmit(true, true, true, true);
        emit MetadataResetToDefault(1);

        vm.prank(memberA);
        memberships.resetMetadataForToken(1);

        assertEq(memberships.tokenURI(1), "ipfs://BASE_HASH/1");
    }

    function test_Burn() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);

        vm.expectEmit(true, true, true, true);
        emit Transfer(memberA, address(0), 1);

        vm.prank(memberA);
        memberships.burn(1);
    }

    function test_Burn_RevertIf_NotOwnerOfToken() public {
        mockInvites.sendImmediateInvite(memberA);
        assertEq(memberships.balanceOf(memberA), 1);
        vm.prank(memberB);
        vm.expectRevert(DefinitelyMemberships.NotOwnerOfToken.selector);
        memberships.burn(1);
    }
}
