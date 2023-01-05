import { ConnectKitProvider } from "connectkit";
import { configureChains, createClient, WagmiConfig } from "wagmi";
import { goerli, mainnet } from "wagmi/chains";
import { CoinbaseWalletConnector } from "wagmi/connectors/coinbaseWallet";
import { InjectedConnector } from "wagmi/connectors/injected";
import { MetaMaskConnector } from "wagmi/connectors/metaMask";
import { WalletConnectConnector } from "wagmi/connectors/walletConnect";
import { alchemyProvider } from "wagmi/providers/alchemy";
import { publicProvider } from "wagmi/providers/public";
import { targetChainId } from "../utils/contracts";

const appName = "DEF DAO";
const alchemyId = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

const { chains, provider, webSocketProvider } = configureChains(
  [mainnet, goerli].filter((c) => c.id === targetChainId),
  [
    ...(alchemyId ? [alchemyProvider({ apiKey: alchemyId })] : []),
    publicProvider(),
  ]
);

const client = createClient({
  autoConnect: true,
  connectors: [
    new MetaMaskConnector({ chains }),
    new CoinbaseWalletConnector({
      chains,
      options: {
        appName: appName,
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

type Props = {
  children: React.ReactNode;
};

export function Web3Provider({ children }: Props) {
  return (
    <WagmiConfig client={client}>
      <ConnectKitProvider
        options={{
          hideTooltips: true,
          walletConnectName: "Wallet Connect",
        }}
      >
        {children}
      </ConnectKitProvider>
    </WagmiConfig>
  );
}
