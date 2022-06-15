// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.10 <0.9.0;

import "forge-std/Test.sol";
import "./Cheats.t.sol";
import "../src/DefinitelyMemberships.sol";
import "../src/DefinitelyMetadata.sol";
import "../src/interfaces/IDefinitelyMemberships.sol";

contract DefinitelyMembershipsTest is DSTest {
    Cheats private constant CHEATS = Cheats(HEVM_ADDRESS);
    DefinitelyMemberships private memberships;
    DefinitelyMetadata private metadata;

    address private owner = CHEATS.addr(uint256(keccak256(abi.encodePacked("owner"))));
    address private memberA = CHEATS.addr(uint256(keccak256(abi.encodePacked("memberA"))));
    address private memberB = CHEATS.addr(uint256(keccak256(abi.encodePacked("memberB"))));

    function setUp() public {
        memberships = new DefinitelyMemberships(owner, metadata);
    }

    function testOwner() public {
        assertEq(memberships.owner(), owner);
    }
}
