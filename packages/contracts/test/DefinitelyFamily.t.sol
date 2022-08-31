// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@murky/Merkle.sol";

import "@def/DefinitelyFamily.sol";
import "@def/DefinitelyMemberships.sol";
import "@def/DefinitelyMetadata.sol";
import "@def/interfaces/IDefinitelyMemberships.sol";
import "@def/interfaces/IDefinitelyMetadata.sol";
import "./mocks/MockInvites.sol";
import "./mocks/MockRevoke.sol";
import "./mocks/MockTransfer.sol";

contract DefinitelyFamilyTest is Test {
    DefinitelyFamily private family;
    DefinitelyMemberships private memberships;
    DefinitelyMetadata private metadata;

    MockInvites private mockInvites;
    MockRevoke private mockRevoke;
    MockTransfer private mockTransfer;

    Merkle private m;
    bytes32[] private allowedMembers;

    address private owner = mkaddr("owner");
    address private memberA = mkaddr("memberA");
    address private memberB = mkaddr("memberB");
    address private memberC = mkaddr("memberC");
    address private memberD = mkaddr("memberD");
    address private memberE = mkaddr("memberE");

    function mkaddr(string memory name) public returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }

    function setUp() public {
        m = new Merkle();

        allowedMembers = new bytes32[](4);
        allowedMembers[0] = keccak256(abi.encodePacked(memberA));
        allowedMembers[1] = keccak256(abi.encodePacked(memberB));
        allowedMembers[2] = keccak256(abi.encodePacked(memberC));
        allowedMembers[3] = keccak256(abi.encodePacked(memberD));

        memberships = new DefinitelyMemberships(owner);
        metadata = new DefinitelyMetadata(owner, address(memberships), "ipfs://BASE_HASH/");
        family = new DefinitelyFamily(owner, address(memberships), m.getRoot(allowedMembers));

        vm.prank(owner);
        memberships.addMembershipIssuingContract(address(family));
    }

    function testOwner() public {
        assertEq(family.owner(), owner);
    }

    function testClaimPriorMembership() public {
        bytes32[] memory proof = m.getProof(allowedMembers, 0);
        vm.prank(memberA);
        family.claimPriorMembership(proof);
    }

    function testCannotClaimPriorMembershipIfNotInMerkleRoot() public {
        bytes32[] memory proof = m.getProof(allowedMembers, 0);
        vm.prank(memberE);
        vm.expectRevert(abi.encodeWithSelector(DefinitelyFamily.NotExistingMember.selector));
        family.claimPriorMembership(proof);
    }

    function testSetExistingMembersClaimRoot() public {
        bytes32[] memory newMembers = new bytes32[](2);
        newMembers[0] = keccak256(abi.encodePacked(memberA));
        newMembers[1] = keccak256(abi.encodePacked(memberB));
        bytes32 root = m.getRoot(newMembers);

        vm.prank(owner);
        family.setExistingMembersClaimRoot(root);
        assertEq(family.existingMembersRoot(), root);
    }

    function testCannotSetExistingMembersClaimRootUnlessOwner() public {
        bytes32[] memory newMembers = new bytes32[](2);
        newMembers[0] = keccak256(abi.encodePacked(memberA));
        newMembers[1] = keccak256(abi.encodePacked(memberB));
        bytes32 root = m.getRoot(newMembers);

        vm.prank(memberA);
        vm.expectRevert("UNAUTHORIZED");
        family.setExistingMembersClaimRoot(root);
        assertEq(family.existingMembersRoot(), m.getRoot(allowedMembers));
    }
}
