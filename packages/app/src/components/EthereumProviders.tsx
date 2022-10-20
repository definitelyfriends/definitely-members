import { ConnectKitProvider } from "connectkit";
import {
  configureChains,
  createClient,
  defaultChains,
  WagmiConfig,
} from "wagmi";
import { CoinbaseWalletConnector } from "wagmi/connectors/coinbaseWallet";
import { InjectedConnector } from "wagmi/connectors/injected";
import { MetaMaskConnector } from "wagmi/connectors/metaMask";
import { WalletConnectConnector } from "wagmi/connectors/walletConnect";
import { alchemyProvider } from "wagmi/providers/alchemy";
import { publicProvider } from "wagmi/providers/public";
import { targetChainId } from "../utils/contracts";

const appName = "DEF DAO";

// Filter chains to target chain ID
const targetChains = defaultChains.filter((c) => c.id === targetChainId);

// Get the alchemy API key to set up a provider
const alchemyApiKey = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

export const { chains, provider, webSocketProvider } = configureChains(
  targetChains,
  [
    ...(alchemyApiKey ? [alchemyProvider({ apiKey: alchemyApiKey })] : []),
    publicProvider(),
  ]
);

export const client = createClient({
  autoConnect: true,
  connectors: [
    new MetaMaskConnector({ chains }),
    new CoinbaseWalletConnector({
      chains,
      options: {
        appName,
        headlessMode: true,
      },
    }),
    new InjectedConnector({
      chains,
      options: {
        name: "Injected",
        shimDisconnect: true,
      },
    }),
    new WalletConnectConnector({
      chains,
      options: {
        qrcode: false,
      },
    }),
  ],
  provider,
  webSocketProvider,
});

interface Props {
  children: React.ReactNode;
}

export function EthereumProviders({ children }: Props) {
  return (
    <WagmiConfig client={client}>
      <ConnectKitProvider>{children}</ConnectKitProvider>
    </WagmiConfig>
  );
}
