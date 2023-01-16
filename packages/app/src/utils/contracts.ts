import DefinitelyClaimableMainnet from "@definitely-members/contracts/deploys/DefinitelyClaimable.1.json";
import DefinitelyClaimableGoerli from "@definitely-members/contracts/deploys/DefinitelyClaimable.5.json";
import DefinitelyInvitesMainnet from "@definitely-members/contracts/deploys/DefinitelyInvites.1.json";
import DefinitelyInvitesGoerli from "@definitely-members/contracts/deploys/DefinitelyInvites.5.json";
import DefinitelyMembershipsMainnet from "@definitely-members/contracts/deploys/DefinitelyMemberships.1.json";
import DefinitelyMembershipsGoerli from "@definitely-members/contracts/deploys/DefinitelyMemberships.5.json";
import DefinitelyClaimableABI from "../abis/DefinitelyClaimable";
import DefinitelyInvitesABI from "../abis/DefinitelyInvites";
import DefinitelyMembershipsABI from "../abis/DefinitelyMemberships";
import DefinitelyGovernance from "~abis/DefinitelyGovernance";

// Will default to goerli if nothing set in the ENV
export const targetChainId = parseInt(
  process.env.NEXT_PUBLIC_CHAIN_ID || "5",
  10
);

export const MEMBERSHIPS_CONTRACT = {
  address: (targetChainId == 1
    ? DefinitelyMembershipsMainnet.address
    : DefinitelyMembershipsGoerli.address) as `0x${string}`,
  abi: DefinitelyMembershipsABI,
};

export const CLAIMABLE_CONTRACT = {
  address: (targetChainId == 1
    ? DefinitelyClaimableMainnet.address
    : DefinitelyClaimableGoerli.address) as `0x${string}`,
  abi: DefinitelyClaimableABI,
};

export const INVITES_CONTRACT = {
  address: (targetChainId == 1
    ? DefinitelyInvitesMainnet.address
    : DefinitelyInvitesGoerli.address) as `0x${string}`,
  abi: DefinitelyInvitesABI,
};

export const GOVERNANCE_CONTRACT = {
  address: DefinitelyGovernance.address as `0x${string}`,
  abi: DefinitelyGovernance.abi,
};

export const CANTO_FORWARDER_CONTRACT = {
  address: "0x3E4404d874fa73659cCfFc21Ac4839EcA21F0b4c",
};
