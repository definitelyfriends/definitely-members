import { EssentialSigner } from "@0xessential/signers";
import { PrepareWriteContractResult } from "@wagmi/core";
import { Abi } from "abitype";
import { Signer } from "ethers";
import * as React from "react";
import { useAccount, UsePrepareContractWriteConfig, useSigner } from "wagmi";
import { CANTO_FORWARDER_CONTRACT } from "../utils/contracts";

export function useGlobalEntryPrepareContractWrite<
  TAbi extends Abi | readonly unknown[],
  TFunctionName extends string
>({
  address,
  abi,
  functionName,
  args,
  overrides,
  onSubmit,
  onError,
  onSettled,
  onSuccess,
}: UsePrepareContractWriteConfig<TAbi, TFunctionName> & {
  onSubmit?: () => void;
}) {
  const { address: signerAddress } = useAccount();
  const { data: signer } = useSigner();

  const globalEntrySigner = React.useMemo(() => {
    if (!signer || !signerAddress) return;
    return new EssentialSigner(signerAddress, signer, {
      domainName: "GlobalEntryForwarder",
      forwarderAddress: CANTO_FORWARDER_CONTRACT.address,
      relayerUri: process.env.NEXT_PUBLIC_RELAYER_URI,
      chainId: 7700,
      rpcUrl: "https://canto.slingshot.finance/",
      onSubmit,
    });
  }, [signer, signerAddress]);

  return {
    config: {
      abi,
      address,
      args,
      functionName,
      mode: "prepared",
      overrides,
      request: undefined,
      signer: globalEntrySigner,
      onError,
      onSettled,
      onSuccess,
    } as unknown as PrepareWriteContractResult<TAbi, TFunctionName> & {
      signer: Signer;
    },
  };
}
