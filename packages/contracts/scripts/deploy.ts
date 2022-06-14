import fs from "fs";
import hre, { ethers, network } from "hardhat";

async function exists(path: string) {
  return await fs.promises
    .access(path)
    .then(() => true)
    .catch(() => false);
}

const start = async () => {
  const [deployer] = await ethers.getSigners();
  const deploysPath = `${__dirname}/../deploys.json`;
  const deploys = (await exists(deploysPath))
    ? JSON.parse((await fs.promises.readFile(deploysPath)).toString())
    : {};

  const baseURI = "ipfs://<CID>";
  const owner = deployer.address;
  const minTransferMembershipQuorum = 6;
  const maxTransferMembershipVotes = 10;
  const minRevokeMembershipQuorum = 11;
  const maxRevokeMembershipVotes = 20;
  const inviteCooldownInSecs = 24 * 60 * 60; // 24 hours

  console.log(`Starting deploy on ${network.name} from ${deployer.address}`);

  console.log("Deploying DefinitelyMetadata...");
  const DefinitelyMetadataFactory = await ethers.getContractFactory(
    "DefinitelyMetadata"
  );
  const metadata = await DefinitelyMetadataFactory.deploy(owner, baseURI);
  console.log("DefinitelyMetadata deployed to", metadata.address);
  console.log("Waiting for 5 confirmations before continuing...");
  const confirmedMetadata = await metadata.deployTransaction.wait(5);

  console.log("Deploying DefinitelyMemberships...");
  const DefinitelyMembershipsFactory = await ethers.getContractFactory(
    "DefinitelyMemberships"
  );
  const memberships = await DefinitelyMembershipsFactory.deploy(
    owner,
    confirmedMetadata.contractAddress,
    minTransferMembershipQuorum,
    maxTransferMembershipVotes,
    minRevokeMembershipQuorum,
    maxRevokeMembershipVotes
  );
  console.log("DefinitelyMemberships deployed to", memberships.address);
  console.log("Waiting for 5 confirmations before continuing...");
  const confirmedMemberships = await memberships.deployTransaction.wait(5);

  console.log("Deploying DefinitelyInvites...");
  const DefinitelyInvitesFactory = await ethers.getContractFactory(
    "DefinitelyInvites"
  );
  const invites = await DefinitelyInvitesFactory.deploy(
    confirmedMemberships.contractAddress,
    inviteCooldownInSecs
  );
  console.log("DefinitelyInvites deployed to", invites.address);
  console.log("Waiting for 5 confirmations before continuing...");
  const confirmedInvites = await invites.deployTransaction.wait(5);

  console.log("Deploying DefinitelyFamily...");
  const DefinitelyFamilyFactory = await ethers.getContractFactory(
    "DefinitelyFamily"
  );
  const family = await DefinitelyFamilyFactory.deploy(
    owner,
    confirmedMemberships.contractAddress,
    []
  );
  console.log("DefinitelyFamily deployed to", family.address);
  console.log("Waiting for 5 confirmations before continuing...");
  const confirmedFamily = await family.deployTransaction.wait(5);

  if (!["hardhat", "localhost"].includes(network.name)) {
    console.log("Verifying contracts...");

    await hre.run("verify:verify", {
      address: confirmedMetadata.contractAddress,
      constructorArguments: [owner, baseURI],
    });
    console.log("DefinitelyMetadata verified");

    await hre.run("verify:verify", {
      address: confirmedMemberships.contractAddress,
      constructorArguments: [
        owner,
        confirmedMetadata.contractAddress,
        minTransferMembershipQuorum,
        maxTransferMembershipVotes,
        minRevokeMembershipQuorum,
        maxRevokeMembershipVotes,
      ],
    });
    console.log("DefinitelyMemberships verified");

    await hre.run("verify:verify", {
      address: confirmedInvites.contractAddress,
      constructorArguments: [
        confirmedMemberships.contractAddress,
        inviteCooldownInSecs,
      ],
    });
    console.log("DefinitelyInvites verified");

    await hre.run("verify:verify", {
      address: confirmedFamily.contractAddress,
      constructorArguments: [owner, confirmedMemberships.contractAddress, []],
    });
    console.log("DefinitelyFamily verified");
  }

  await fs.promises.writeFile(
    "deploys.json",
    JSON.stringify(
      {
        ...deploys,
        DefinitelyMemberships: {
          ...deploys.DefinitelyMemberships,
          [network.name]: {
            address: confirmedMemberships.contractAddress,
            blockNumber: confirmedMemberships.blockNumber,
          },
        },
        DefinitelyMetadataFactory: {
          ...deploys.DefinitelyMetadataFactory,
          [network.name]: {
            address: confirmedMetadata.contractAddress,
            blockNumber: confirmedMetadata.blockNumber,
          },
        },
        DefinitelyInvitesFactory: {
          ...deploys.DefinitelyInvitesFactory,
          [network.name]: {
            address: confirmedInvites.contractAddress,
            blockNumber: confirmedInvites.blockNumber,
          },
        },
        DefinitelyFamilyFactory: {
          ...deploys.DefinitelyFamilyFactory,
          [network.name]: {
            address: confirmedFamily.contractAddress,
            blockNumber: confirmedFamily.blockNumber,
          },
        },
      },
      null,
      2
    )
  );
};

start().catch((e: Error) => {
  console.error(e);
  process.exit(1);
});
