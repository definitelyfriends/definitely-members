import { useQuery } from "@tanstack/react-query";
import { getProof } from "lanyard";
import { useContractRead } from "wagmi";
import { CLAIMABLE_CONTRACT } from "../utils/contracts";

type MerkleProofOptions = {
  address?: string;
};

export function useMerkleProof({ address }: MerkleProofOptions) {
  const { data } = useContractRead({
    ...CLAIMABLE_CONTRACT,
    functionName: "claimableRoot",
  });

  return useQuery(
    ["proof", address],
    async () => {
      if (!address) return null;
      const proofRes = await getProof({
        merkleRoot: data ? data.toString() : "",
        unhashedLeaf: address.toString(),
      });

      if (!proofRes) {
        return Promise.reject(new Error("Account not in current merkle tree"));
      }

      return proofRes.proof;
    },
    {
      enabled: Boolean(address && data),
      retry: false,
    }
  );
}
