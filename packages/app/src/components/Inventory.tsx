import { useQuery } from "@tanstack/react-query";
import { useAccount } from "wagmi";
import { graphql } from "../graphql";
import { graphQlClient } from "../graphql/client";
import { useIsMounted } from "../hooks/useIsMounted";
import { useOpenSea } from "../hooks/useOpenSea";
// import { exampleNFT } from "../utils/contracts";
import { LoadingIndicator } from "./LoadingIndicator";
import { Body, Subheading } from "./Typography";

const inventoryQueryDocument = graphql(/* GraphQL */ `
  query Inventory($owner: String!) {
    tokens(where: { owner: $owner }, first: 100) {
      id
      tokenURI
    }
  }
`);

export function Inventory() {
  const isMounted = useIsMounted();
  const { address } = useAccount();

  const { data, isLoading } = useQuery(
    ["inventoryByOwner", address],
    async () =>
      graphQlClient.request(inventoryQueryDocument, {
        owner: address ? address.toLowerCase() : "",
      }),
    {
      enabled: Boolean(address),
    }
  );

  const { getAssetUrl } = useOpenSea();

  if (!isMounted || !address) return null;

  if (!data || isLoading) {
    return (
      <Body>
        <LoadingIndicator /> Loading
      </Body>
    );
  }

  return (
    <div>
      <Subheading margin="24 0 0">Inventory</Subheading>
      <div>
        {data.tokens.length > 0 ? (
          <>
            {/* {data.tokens.map((token) => (
              <a
                key={token.id}
                href={getAssetUrl(exampleNFT.address, token.id)}
                target="_blank"
                rel="noopener noreferrer"
              >
                <Body>Token #{token.id}</Body>
              </a>
            ))} */}
          </>
        ) : (
          <Body>You don't own any NFTs</Body>
        )}
      </div>
    </div>
  );
}
