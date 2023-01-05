import { useCallback } from "react";
import { goerli, mainnet } from "wagmi/chains";
import { targetChainId } from "../utils/contracts";

export function useEtherscan() {
  let explorerURL = mainnet.blockExplorers?.default.url;
  if (targetChainId === 5) {
    explorerURL = goerli.blockExplorers?.default.url;
  }

  const getTransactionUrl = useCallback(
    (hash: string) => explorerURL && `${explorerURL}/tx/${hash}`,
    [explorerURL]
  );

  const getAddressUrl = useCallback(
    (address: string) => explorerURL && `${explorerURL}/address/${address}`,
    [explorerURL]
  );

  return { getTransactionUrl, getAddressUrl };
}
