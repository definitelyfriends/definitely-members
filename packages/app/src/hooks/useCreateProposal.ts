import { TransactionReceipt } from "@ethersproject/providers";
import { BigNumber, utils } from "ethers";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils.js";
import { useMemo } from "react";
import { useAccount, useWaitForTransaction } from "wagmi";
import { GOVERNANCE_CONTRACT, MEMBERSHIPS_CONTRACT } from "../utils/contracts";

import { useGlobalEntryContractWrite } from "./useGlobalEntryContractWrite";
import { useGlobalEntryPrepareContractWrite } from "./useGlobalEntryPrepareContractWrite";
import { useMemberQuery } from "./useMemberQuery";

type Options = {
  description: string;
  onPrepareError?: (error: Error) => void;
  onTxSuccess?: (data: TransactionReceipt) => void;
  onTxError?: (error: Error) => void;
};

export function useCreateProposal({
  onPrepareError,
  onTxSuccess,
  onTxError,
  description,
}: Options) {
  const { address } = useAccount();

  const { data: membership } = useMemberQuery(address || "0x");

  const proposalId = useMemo(() => {
    const abi = new utils.AbiCoder();
    return BigNumber.from(
      keccak256(
        abi.encode(
          ["address[]", "uint256[]", "bytes[]", "bytes32"],
          [
            [MEMBERSHIPS_CONTRACT.address],
            [0],
            ["0x"],
            keccak256(toUtf8Bytes(description)),
          ]
        )
      )
    );
  }, [description]);

  const proposePrepare = useGlobalEntryPrepareContractWrite({
    ...GOVERNANCE_CONTRACT,
    functionName: "propose(address[],uint256[],bytes[],string)" as "propose",
    args: [
      [MEMBERSHIPS_CONTRACT.address as `0x${string}`],
      [BigNumber.from(0)],
      ["0x"],
      description,
    ],
    overrides: {
      customData: {
        authorizer: address,
        nftContract: MEMBERSHIPS_CONTRACT.address,
        nftTokenId: membership?.tokenId,
        nftChainId: process.env.NEXT_PUBLIC_CHAIN_ID,
      },
    },
    enabled: Boolean(description && address && membership?.tokenId),
    onError: (error) => {
      if (onPrepareError) {
        onPrepareError(error);
      }
    },
  });

  const propose = useGlobalEntryContractWrite(proposePrepare.config);

  const proposeTx = useWaitForTransaction({
    confirmations: 1,
    hash: propose.data?.hash as `0x${string}`,
    enabled: !!propose?.data?.hash,
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
    proposalId,
    proposePrepare,
    propose,
    proposeTx,
  };
}
