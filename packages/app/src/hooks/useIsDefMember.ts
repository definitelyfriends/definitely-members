import { useContractRead } from "wagmi";
import { MEMBERSHIPS_CONTRACT } from "../utils/contracts";

type Options = {
  address: `0x${string}` | undefined;
  onSettled?: (isMember: boolean | undefined, error: Error | null) => void;
  onSuccess?: (isMember: boolean) => void;
};

export function useIsDefMember({ address, onSuccess, onSettled }: Options) {
  const { data, ...query } = useContractRead({
    ...MEMBERSHIPS_CONTRACT,
    functionName: "balanceOf",
    args: [address || "0x"],
    enabled: Boolean(address),
    onSuccess: (data) => {
      if (onSuccess) {
        onSuccess(Boolean(data.gt(0)));
      }
    },
    onSettled: (data, error) => {
      if (onSettled) {
        onSettled(data && data.gt(0), error);
      }
    },
  });

  return {
    isDefMember: Boolean(data && data.gt(0)),
    ...query,
  };
}
