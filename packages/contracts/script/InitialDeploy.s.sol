// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "forge-std/Script.sol";

import "@def/DefinitelyMemberships.sol";
import "@def/DefinitelyMetadata.sol";
import "@def/DefinitelyFamily.sol";

contract InitialDeploy is Script {
    // Deployable contracts
    DefinitelyMemberships public memberships;
    DefinitelyMetadata public metadata;
    DefinitelyFamily public family;

    function run() public {
        // Deployment config
        address owner = msg.sender;

        // Start deployment
        vm.startBroadcast();

        // Deploy membership contract
        memberships = new DefinitelyMemberships(owner);

        // Deploy metadata contract
        metadata = new DefinitelyMetadata(
            owner,
            address(memberships),
            "ipfs://QmNTMDN9xVFxD9Z2Cfh9sHYc3RJEMBq2Jr3dBqjDmWDTLZ/"
        );

        // Deploy family merkle root contract
        family = new DefinitelyFamily(
            owner,
            address(memberships),
            0x4964b4eb9187a0dae85c41cf50e9b13b493e3718c4591a1ea912ca6566760d38
        );

        // Add the family contract so it can issue memberships
        memberships.addMembershipIssuingContract(address(family));

        // Finish deployment
        vm.stopBroadcast();
    }
}
