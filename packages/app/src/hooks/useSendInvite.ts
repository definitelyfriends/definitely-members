import { TransactionReceipt } from "@ethersproject/providers";
import {
  useAccount,
  useContractRead,
  useContractWrite,
  usePrepareContractWrite,
  useWaitForTransaction,
} from "wagmi";
import { INVITES_CONTRACT } from "../utils/contracts";
import { useIsDefMember } from "./useIsDefMember";

type Options = {
  to: `0x${string}`;
  onPrepareError?: (error: Error) => void;
  onTxSuccess?: (data: TransactionReceipt) => void;
  onTxError?: (error: Error) => void;
};

export function useSendInvite({
  to,
  onPrepareError,
  onTxSuccess,
  onTxError,
}: Options) {
  const { address } = useAccount();

  const { data: hasInviteAvailable } = useContractRead({
    ...INVITES_CONTRACT,
    functionName: "inviteAvailable",
    args: [to],
    enabled: Boolean(to),
  });

  const { isDefMember } = useIsDefMember({ address: to });

  const invitePrepare = usePrepareContractWrite({
    ...INVITES_CONTRACT,
    functionName: "sendClaimableInvite",
    args: [to],
    enabled: Boolean(
      address && to && !hasInviteAvailable && isDefMember === false
    ),
    onError: (error) => {
      if (onPrepareError) {
        onPrepareError(error);
      }
    },
  });

  const invite = useContractWrite(invitePrepare.config);

  const inviteTx = useWaitForTransaction({
    confirmations: 1,
    hash: invite.data?.hash,
    enabled: !!invite.data,
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
    invitePrepare,
    invite,
    inviteTx,
  };
}
