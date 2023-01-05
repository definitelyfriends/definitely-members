import { TransactionReceipt } from "@ethersproject/providers";
import {
  useAccount,
  useContractRead,
  useContractWrite,
  usePrepareContractWrite,
  useWaitForTransaction,
} from "wagmi";
import { INVITES_CONTRACT } from "../utils/contracts";

type Options = {
  onPrepareError?: (error: Error) => void;
  onTxSuccess?: (data: TransactionReceipt) => void;
  onTxError?: (error: Error) => void;
};

export function useClaimInvite({
  onPrepareError,
  onTxSuccess,
  onTxError,
}: Options) {
  const { address } = useAccount();

  const { data: hasInviteAvailable } = useContractRead({
    ...INVITES_CONTRACT,
    functionName: "inviteAvailable",
    args: [address || "0x"],
    enabled: Boolean(address),
  });

  const claimPrepare = usePrepareContractWrite({
    ...INVITES_CONTRACT,
    functionName: "claimInvite",
    enabled: Boolean(hasInviteAvailable && address),
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
    onSuccess: (data) => {
      if (onTxSuccess) {
        onTxSuccess(data);
      }
    },
    onError: (error) => {
      if (onTxError) {
        onTxError(error);
      }
    },
  });

  return {
    hasInviteAvailable,
    claimPrepare,
    claim,
    claimTx,
  };
}
