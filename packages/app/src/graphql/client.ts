import { GraphQLClient } from "graphql-request";

export const graphQlClient = new GraphQLClient(
  "https://api.thegraph.com/subgraphs/name/samkingco/example-nft"
);
