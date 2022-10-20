// import ExampleNFTMainnet from "@definitely-members/contracts/deploys/nft.1.json";
// import ExampleNFTGoerli from "@definitely-members/contracts/deploys/nft.5.json";
// import ExampleNFTABI from "../abis/ExampleNFT";

// Will default to goerli if nothing set in the ENV
export const targetChainId = parseInt(
  process.env.NEXT_PUBLIC_CHAIN_ID || "5",
  10
);

// export const exampleNFT = {
//   address:
//     targetChainId == 1 ? ExampleNFTMainnet.address : ExampleNFTGoerli.address,
//   abi: ExampleNFTABI,
// };
