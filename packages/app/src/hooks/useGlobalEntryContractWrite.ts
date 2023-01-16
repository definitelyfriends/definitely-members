import { TransactionResponse } from "@ethersproject/providers";

import { Abi } from "abitype";
import { constants, Contract, Signer, utils } from "ethers";
import * as React from "react";
import { useAccount, UseContractWriteConfig } from "wagmi";

export function useGlobalEntryContractWrite<
  TAbi extends Abi | readonly unknown[],
  TFunctionName extends string
>({
  address,
  args,
  abi,
  functionName,
  overrides,
  onError,
  onSuccess,
  signer,
}: UseContractWriteConfig<"prepared", TAbi, TFunctionName> & {
  signer: Signer;
}) {
  const [data, setData] = React.useState<TransactionResponse>();
  const { address: authorizer } = useAccount();
  const [isLoading, setLoading] = React.useState(false);

  const defaultValues = {
    error: null,
    isError: false,
    isIdle: true,
    isLoading: false,
    isSuccess: null,
  };

  const write = React.useCallback(() => {
    const implementationContract = new Contract(
      address!,
      new utils.Interface(abi! as any),
      signer
    );

    const flatArgs = [
      ...(args ? args : [null]),
      ...(overrides
        ? [overrides]
        : [
            {
              customData: {
                authorizer,
                nftContract: constants.AddressZero,
                nftTokenId: 0,
                nftChainId: 0,
              },
            },
          ]),
    ];

    setLoading(true);
    console.warn(implementationContract);
    return implementationContract[functionName as string]
      .apply(null, flatArgs)
      .then((resp: TransactionResponse) => {
        setData(resp);
        onSuccess?.(resp as any, {} as any, null);
        setLoading(false);
      })
      .catch((e: Error) => {
        onError?.(e, {} as any, null);
        setLoading(false);
      });
  }, [
    address,
    abi,
    signer,
    args,
    overrides,
    authorizer,
    functionName,
    onSuccess,
    onError,
  ]);

  return {
    ...defaultValues,
    isLoading,
    data,
    write,
  };
}
