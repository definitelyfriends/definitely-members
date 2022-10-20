// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import "def/DefinitelyMemberships.sol";
import "def/DefinitelyMetadata.sol";
import "def/DefinitelyClaimable.sol";
import "def/DefinitelyInvites.sol";
import "def/DefinitelyRevoke.sol";
import "def/DefinitelySoulboundRecovery.sol";

contract InitialDeploy is Script {
    // Deployable contracts
    DefinitelyMemberships public memberships;
    DefinitelyMetadata public metadata;
    DefinitelyClaimable public claimable;
    DefinitelyInvites public invites;
    DefinitelyRevoke public revoke;
    DefinitelySoulboundRecovery public recovery;

    function writeContractJSON(address deployedTo, string memory filename) public {
        // Get the chain ID
        string memory chainId = vm.envString("FOUNDRY_CHAIN_ID");

        string memory json = string.concat(
            '{"address": "',
            vm.toString(deployedTo),
            '", "blockNumber": ',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(
            string.concat("packages/contracts/deploys/", filename, ".", chainId, ".json"),
            json
        );
    }

    function run() public {
        // Deployment config
        address owner = msg.sender;
        address admin = msg.sender;
        address signer = address(0xBEEF);

        // Start deployment
        vm.startBroadcast();

        // Deploy membership contract
        memberships = new DefinitelyMemberships(owner, admin);

        // Deploy metadata contract
        metadata = new DefinitelyMetadata(
            admin,
            address(memberships),
            "ipfs://QmNTMDN9xVFxD9Z2Cfh9sHYc3RJEMBq2Jr3dBqjDmWDTLZ/"
        );

        // Set the default metadata contract
        memberships.setDefaultMetadata(address(metadata));

        // Deploy claimable memberships contract
        claimable = new DefinitelyClaimable(owner, address(memberships), signer);

        // Deploy the invites contract
        uint256 inviteCooldown = 24 hours;
        invites = new DefinitelyInvites(owner, address(memberships), inviteCooldown);

        // Voting configs
        uint64 minQuorum = 7;
        uint64 maxVotes = 10;

        // Deploy the membership revoking contract
        revoke = new DefinitelyRevoke(owner, address(memberships), minQuorum, maxVotes);

        // Deploy the membership recovery contract
        recovery = new DefinitelySoulboundRecovery(
            owner,
            address(memberships),
            minQuorum,
            maxVotes
        );

        // Add issuing contracts
        memberships.addMembershipIssuingContract(address(claimable));
        memberships.addMembershipIssuingContract(address(invites));

        // Add revoking contracts
        memberships.addMembershipRevokingContract(address(revoke));

        // Add transfer contracts
        memberships.addMembershipTransferContract(address(recovery));

        writeContractJSON(address(memberships), "DefinitelyMemberships");
        writeContractJSON(address(metadata), "DefinitelyMetadata");
        writeContractJSON(address(claimable), "DefinitelyClaimable");
        writeContractJSON(address(revoke), "DefinitelyRevoke");
        writeContractJSON(address(recovery), "DefinitelySoulboundRecovery");

        // Finish deployment
        vm.stopBroadcast();
    }
}
