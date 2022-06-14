import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import dotenv from "dotenv";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
      blockGasLimit: 100000000,
    },
    goerli: {
      url: process.env.ETHEREUM_GOERLI_RPC_URL || "",
      accounts: process.env.ETHEREUM_GOERLI_DEPLOYER_PRIVATE_KEY
        ? [process.env.ETHEREUM_GOERLI_DEPLOYER_PRIVATE_KEY]
        : [],
    },
    mainnet: {
      url: process.env.ETHEREUM_MAINNET_RPC_URL || "",
      accounts: process.env.ETHEREUM_MAINNET_DEPLOYER_PRIVATE_KEY
        ? [process.env.ETHEREUM_MAINNET_DEPLOYER_PRIVATE_KEY]
        : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    token: "ETH",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    excludeContracts: ["mocks/"],
  },
};
