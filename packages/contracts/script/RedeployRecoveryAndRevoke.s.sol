// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import "def/DefinitelyMemberships.sol";
import "def/DefinitelyRevoke.sol";
import "def/DefinitelySocialRecovery.sol";

contract RedeployRecoveryAndRevoke is Script {
    // Deployable contracts
    DefinitelyMemberships public memberships;
    DefinitelyRevoke public revoke;
    DefinitelySocialRecovery public recovery;

    function writeContractJSON(address deployedTo, string memory filename) public {
        string memory json = string.concat(
            '{"address": "',
            vm.toString(deployedTo),
            '", "blockNumber": ',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(
            string.concat(
                "packages/contracts/deploys/",
                filename,
                ".",
                vm.toString(block.chainid),
                ".json"
            ),
            json
        );
    }

    function run() public {
        // Deployment config
        address owner = msg.sender;
        memberships = DefinitelyMemberships(0x3193046D450Dade9ca17F88db4A72230140E64dC);

        // Start deployment
        vm.startBroadcast();

        // Remove existing contracts
        memberships.removeMembershipRevokingContract(0x9e497307DA0fc376256E5d6B2C75E002DF1A8786);
        memberships.removeMembershipTransferContract(0x6E4D8d078A403Cc8B69b823d87E5da95DF559Ca8);

        // Voting configs
        uint64 minQuorum = 6;
        uint64 maxVotes = 10;

        // Deploy the membership revoking contract
        revoke = new DefinitelyRevoke(owner, address(memberships), minQuorum, maxVotes);

        // Deploy the membership recovery contract
        recovery = new DefinitelySocialRecovery(owner, address(memberships), minQuorum, maxVotes);

        // Add revoking contracts
        memberships.addMembershipRevokingContract(address(revoke));

        // Add transfer contracts
        memberships.addMembershipTransferContract(address(recovery));

        // Save the JSON
        writeContractJSON(address(revoke), "DefinitelyRevoke");
        writeContractJSON(address(recovery), "DefinitelySocialRecovery");

        // Finish deployment
        vm.stopBroadcast();
    }
}
