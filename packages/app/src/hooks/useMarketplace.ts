import { useCallback } from "react";
import { goerli, mainnet } from "wagmi/chains";
import { targetChainId } from "../utils/contracts";

export function useMarketplace() {
  let openSeaUrl = "https://opensea.io";
  let looksRareUrl = "https://looksrare.org";
  let gemUrl = "https://gem.xyz";

  const chain =
    [mainnet, goerli].find((i) => i.id === targetChainId) || mainnet;
  let assetName = chain.id === 1 ? "ethereum" : chain.name;

  if (targetChainId !== 1) {
    openSeaUrl = "https://testnets.opensea.io";
    looksRareUrl = `https://${assetName}.looksrare.org`;
  }

  const getOpenSeaUrl = useCallback(
    (contract: string, tokenId: string) =>
      `${openSeaUrl}/assets/${assetName}/${contract}/${tokenId}`,
    [openSeaUrl, assetName]
  );

  const getLooksRareUrl = useCallback(
    (contract: string, tokenId: string) =>
      `${looksRareUrl}/collections/${contract}/${tokenId}`,
    [looksRareUrl]
  );

  const getGemUrl = useCallback(
    (contract: string, tokenId: string) =>
      `${gemUrl}/asset/${contract}/${tokenId}`,
    [gemUrl]
  );

  return { getOpenSeaUrl, getLooksRareUrl, getGemUrl };
}
