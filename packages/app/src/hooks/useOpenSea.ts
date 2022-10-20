import { useCallback } from "react";
import { useNetwork } from "wagmi";
import { targetChainId } from "../utils/contracts";

export function useOpenSea() {
  const { chain } = useNetwork();
  const chainId = chain ? chain.id : targetChainId;

  let openSeaUrl = "https://opensea.io";
  let assetName =
    chainId !== 1 && chain ? chain.name.toLowerCase() : "ethereum";

  if (chainId !== 1) {
    openSeaUrl = "https://testnets.opensea.io";
  }

  const getAssetUrl = useCallback(
    (contract: string, tokenId: string) =>
      `${openSeaUrl}/assets/${assetName}/${contract}/${tokenId}`,
    [openSeaUrl, assetName]
  );

  return { getAssetUrl };
}
