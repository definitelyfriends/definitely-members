import { useCallback } from "react";
import { etherscanBlockExplorers, useNetwork } from "wagmi";
import { targetChainId } from "../utils/contracts";

export function useEtherscan() {
  const { chain } = useNetwork();
  const chainId = chain ? chain.id : targetChainId;

  let explorerURL = etherscanBlockExplorers.mainnet.url;
  if (chainId === 5) {
    explorerURL = etherscanBlockExplorers.goerli.url;
  }

  const getTransactionUrl = useCallback(
    (hash: string) => `${explorerURL}/tx/${hash}`,
    [explorerURL]
  );

  const getAddressUrl = useCallback(
    (address: string) => `${explorerURL}/address/${address}`,
    [explorerURL]
  );

  return { getTransactionUrl, getAddressUrl };
}
