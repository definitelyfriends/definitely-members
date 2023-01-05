import {
  useAccount,
  useContractWrite,
  usePrepareContractWrite,
  useWaitForTransaction,
} from "wagmi";
import { CLAIMABLE_CONTRACT } from "../utils/contracts";
import { useMerkleProof } from "./useMerkleProof";

function massageProof(data: string[] | undefined): `0x${string}`[] {
  if (data && data.length === 0) {
    const proof: `0x${string}`[] = [];
    data.forEach((i) => proof.push(i as `0x${string}`));
    return proof;
  }
  return [];
}

type Options = {
  onPrepareError?: (error: Error) => void;
  onTxSuccess?: () => void;
  onTxError?: (error: Error) => void;
};

export function useClaimMembership({
  onPrepareError,
  onTxSuccess,
  onTxError,
}: Options) {
  const withVault = true;

  const { address } = useAccount();
  const { data: merkleProof } = useMerkleProof({
    address,
  });

  const proof = massageProof(merkleProof || undefined);

  const claimPrepare = usePrepareContractWrite({
    address: CLAIMABLE_CONTRACT.address as `0x${string}`,
    abi: [
      {
        inputs: [
          { internalType: "bytes32[]", name: "proof", type: "bytes32[]" },
        ],
        name: "claimMembership",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
      },
    ],
    functionName: "claimMembership",
    args: [proof],
    enabled: Boolean(proof && address),
    onError: (error) => {
      if (onPrepareError) {
        onPrepareError(error);
      }
    },
  });

  const claim = useContractWrite(claimPrepare.config);

  const claimTx = useWaitForTransaction({
    confirmations: 1,
    hash: claim.data?.hash,
    enabled: !!claim.data,
    onSuccess: () => {
      if (onTxSuccess) {
        onTxSuccess();
      }
    },
    onError: (error) => {
      if (onTxError) {
        onTxError(error);
      }
    },
  });

  return {
    claimPrepare,
    claim,
    claimTx,
  };
}
