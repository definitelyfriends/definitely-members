import {
  useAccount,
  useContractWrite,
  usePrepareContractWrite,
  useWaitForTransaction,
} from "wagmi";
import { CLAIMABLE_CONTRACT } from "../utils/contracts";
import { useMerkleProof } from "./useMerkleProof";

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
  const { address } = useAccount();
  const { data: merkleProof } = useMerkleProof({
    address,
  });

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
    // TODO: Correctly type the proof to remove ts-ignore
    // @ts-ignore
    args: [merkleProof],
    enabled: Boolean(merkleProof && address),
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
