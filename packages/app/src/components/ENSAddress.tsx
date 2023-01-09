import { useENS } from "../hooks/useENS";

type Props = {
  address: string | undefined;
};

export function ENSAddress({ address }: Props) {
  const { displayName } = useENS(address);
  if (!address) return null;
  return <>{displayName}</>;
}
