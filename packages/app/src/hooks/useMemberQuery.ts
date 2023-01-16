import { useQuery } from "@tanstack/react-query";
import { BigNumber } from "ethers";
import { RequestDocument } from "graphql-request";
import { useAccount } from "wagmi";
import { graphql } from "../graphql";
import { graphQlClient } from "../graphql/client";

const memberQueryDocument = graphql(/* GraphQL */ `
  query MemberQuery($address: ID!) {
    wallet(id: $address) {
      address
      isMember
      joinedBlockNumber
      joinedTimestamp
      joinedTxHash
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

export function useMemberQuery(address: `0x${string}`) {
  return useQuery(["memberQuery"], async () => {
    const data = await graphQlClient.request(
      memberQueryDocument as RequestDocument,
      {
        address: address?.toLocaleLowerCase(),
      }
    );

    const { wallet } = data;

    if (wallet) {
      return {
        id: wallet.address as string,
        address: wallet.address as string,
        joinedBlockNumber: BigNumber.from(wallet.joinedBlockNumber).toNumber(),
        joinedTimestamp: BigNumber.from(wallet.joinedTimestamp).toNumber(),
        joinedTxHash: wallet.joinedTxHash as string,
        tokenId: wallet.tokens.length > 0 ? wallet.tokens[0].id : null,
        invited:
          wallet.invited && wallet.invited.length > 0
            ? wallet.invited.map((i: any) => i.address as string)
            : [],
        invitedBy: wallet.invitedBy
          ? (wallet.invitedBy.address as string)
          : null,
      };
    }
    return {};
  });
}
