import { useQuery } from "@tanstack/react-query";
import { BigNumber } from "ethers";
import { graphql } from "../graphql";
import { graphQlClient } from "../graphql/client";

export const membersQueryDocument = graphql(/* GraphQL */ `
  query MembersQuery {
    wallets(
      orderBy: joinedTimestamp
      orderDirection: asc
      where: { isMember: true }
    ) {
      address
      isMember
      joinedBlockNumber
      joinedTimestamp
      tokens(first: 1) {
        id
      }
      invited {
        address
      }
      invitedBy {
        address
      }
    }
  }
`);

export function useMembersQuery() {
  return useQuery(["membersQuery"], async () => {
    const data = await graphQlClient.request(membersQueryDocument);

    if (data.wallets) {
      return data.wallets.map((wallet) => ({
        id: wallet.address as string,
        address: wallet.address as string,
        joinedBlockNumber: BigNumber.from(wallet.joinedBlockNumber).toNumber(),
        joinedTimestamp: BigNumber.from(wallet.joinedTimestamp).toNumber(),
        tokenId: wallet.tokens.length > 0 ? wallet.tokens[0].id : null,
        invited:
          wallet.invited && wallet.invited.length > 0
            ? wallet.invited.map((i: any) => i.address as string)
            : [],
        invitedBy: wallet.invitedBy
          ? (wallet.invitedBy.address as string)
          : null,
      }));
    }
    return data.wallets;
  });
}
