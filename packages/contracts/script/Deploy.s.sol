// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import "def/DefinitelyMemberships.sol";
import "def/DefinitelyMetadata.sol";
import "def/DefinitelyClaimable.sol";
import "def/DefinitelyInvites.sol";
import "def/DefinitelyRevoke.sol";
import "def/DefinitelySocialRecovery.sol";

contract InitialDeploy is Script {
    // Deployable contracts
    DefinitelyMemberships public memberships;
    DefinitelyMetadata public metadata;
    DefinitelyClaimable public claimable;
    DefinitelyInvites public invites;
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

        // Merkle root with initial users:
        // gear.samking.eth
        // frolic.eth
        // jamiedubs.eth
        // chd.eth
        // 0xyoshi.eth
        bytes32 claimableRoot = 0x714eddee19e5de4d354f3b5cd05b651a60b13b0181a79cfa5d84799bb31f28cd;

        // Start deployment
        vm.startBroadcast();

        // Deploy membership contract
        memberships = new DefinitelyMemberships(owner);

        // Add some admin accounts
        memberships.addAdmin(0x34b944a2A4F4c49B34f7a12Ee570cA10e2039AB1); // gear.samking.eth
        memberships.addAdmin(0xC9C022FCFebE730710aE93CA9247c5Ec9d9236d0); // frolic.eth
        memberships.addAdmin(0xD9C4475E2dd89a9a0aD0C1E9a1e1bb28Df7BA298); // jamiedubs.eth
        memberships.addAdmin(0x0ec364eFccB98eD3656C280a816631C1663eF0ba); // chd.eth
        memberships.addAdmin(0xE332de3c84C305698675A73F366061941C78e3b4); // 0xyoshi.eth

        // Deploy metadata contract
        metadata = new DefinitelyMetadata(
            owner,
            address(memberships),
            "ipfs://QmNTMDN9xVFxD9Z2Cfh9sHYc3RJEMBq2Jr3dBqjDmWDTLZ"
        );

        // Set the default metadata contract
        memberships.setDefaultMetadata(address(metadata));

        // Deploy claimable memberships contract
        claimable = new DefinitelyClaimable(owner, address(memberships), claimableRoot);

        // Deploy the invites contract
        uint256 inviteCooldown = 0;
        invites = new DefinitelyInvites(owner, address(memberships), inviteCooldown);

        // Voting configs
        uint64 minQuorum = 6;
        uint64 maxVotes = 10;

        // Deploy the membership revoking contract
        revoke = new DefinitelyRevoke(owner, address(memberships), minQuorum, maxVotes);

        // Deploy the membership recovery contract
        recovery = new DefinitelySocialRecovery(owner, address(memberships), minQuorum, maxVotes);

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
        writeContractJSON(address(recovery), "DefinitelySocialRecovery");

        // Finish deployment
        vm.stopBroadcast();
    }
}
