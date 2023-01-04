// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "murky/Merkle.sol";

import "def/DefinitelyClaimable.sol";
import "def/DefinitelyMemberships.sol";
import "def/interfaces/IDefinitelyMemberships.sol";
import "./mocks/MockInvites.sol";

contract DefinitelyClaimableTest is Test {
    DefinitelyClaimable private claimable;
    DefinitelyMemberships private memberships;

    Merkle private merkle;
    MockInvites private mockInvites;

    address private owner = makeAddr("owner");
    address private memberA = makeAddr("memberA");
    address private memberB = makeAddr("memberB");
    address private memberC = makeAddr("memberC");

    address[10] private merkleAccounts;

    event MembershipClaimed(address indexed member);
    event ClaimableRootUpdated(bytes32 indexed root);
    event DelegationRegistryUpdated(address indexed registry);

    function setUp() public {
        string[10] memory chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];

        for (uint256 i = 0; i < merkleAccounts.length; i++) {
            merkleAccounts[i] = makeAddr(string(abi.encodePacked("merkle", chars[i])));
        }

        merkle = new Merkle();
        bytes32[] memory data = createMerkleData();
        bytes32 root = merkle.getRoot(data);

        memberships = new DefinitelyMemberships(owner);
        claimable = new DefinitelyClaimable(owner, address(memberships), root);

        mockInvites = new MockInvites(address(memberships));

        vm.startPrank(owner);
        memberships.addMembershipIssuingContract(address(claimable));
        memberships.addMembershipIssuingContract(address(mockInvites));
        vm.stopPrank();

        // Set a fixed date before every test, otherwise block.timestamp will be 1
        // which won't happen IRL, but will cause cooldown conditions to break
        vm.warp(1649286000);
    }

    function createMerkleData() internal view returns (bytes32[] memory) {
        bytes32[] memory data = new bytes32[](merkleAccounts.length);
        for (uint256 i = 0; i < merkleAccounts.length; i++) {
            data[i] = keccak256(abi.encodePacked(merkleAccounts[i]));
        }
        return data;
    }

    function test_SetUp() public {
        assertEq(claimable.owner(), owner);
    }

    function test_ClaimMembership() public {
        bytes32[] memory data = createMerkleData();
        bytes32[] memory proof = merkle.getProof(data, 0);
        address account = merkleAccounts[0];

        assertEq(memberships.balanceOf(account), 0);
        assertEq(claimable.canClaimMembership(account, proof), true);

        vm.expectEmit(true, true, true, true);
        emit MembershipClaimed(account);

        vm.prank(account);
        claimable.claimMembership(proof);

        assertEq(memberships.balanceOf(account), 1);
    }

    function test_ClaimMembership_RevertIf_InvalidProof() public {
        bytes32[] memory data = createMerkleData();
        bytes32[] memory proof = merkle.getProof(data, 1);
        address account = merkleAccounts[0];

        assertEq(memberships.balanceOf(account), 0);

        vm.prank(account);
        vm.expectRevert(DefinitelyClaimable.InvalidProof.selector);
        claimable.claimMembership(proof);
        assertEq(memberships.balanceOf(account), 0);
    }
}
