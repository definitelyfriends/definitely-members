import { useContractRead } from "wagmi";
import { MEMBERSHIPS_CONTRACT } from "../utils/contracts";

type Options = {
  address: `0x${string}` | undefined;
};

export function useIsDefMember({ address }: Options) {
  const { data, ...query } = useContractRead({
    address: MEMBERSHIPS_CONTRACT.address as `0x${string}`,
    abi: [
      {
        inputs: [{ internalType: "address", name: "owner", type: "address" }],
        name: "balanceOf",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function",
      },
    ],
    functionName: "balanceOf",
    args: [address || "0x"],
    enabled: Boolean(address),
  });

  return {
    isDefMember: Boolean(data && data.gt(0)),
    ...query,
  };
}
