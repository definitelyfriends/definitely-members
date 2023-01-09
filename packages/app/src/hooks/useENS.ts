import { useQuery } from "@tanstack/react-query";

function addressDisplayName(address?: string) {
  if (!address) return "";
  const match = address.match(
    /^(0x[a-zA-Z0-9]{3})[a-zA-Z0-9]+([a-zA-Z0-9]{4})$/
  );
  if (!match) return address;
  return `${match[1]}…${match[2]}`;
}

type ENSResponse = {
  address: string | undefined;
  name: string | null;
  displayName: string;
  avatar: string | null;
};

export function useENS(address?: string) {
  const addressLowercase = address && address.toLowerCase();

  const placeholder: ENSResponse = {
    address: addressLowercase,
    name: null,
    displayName: addressDisplayName(addressLowercase),
    avatar: null,
  };

  const { data, ...ensQuery } = useQuery(
    ["ensResolver", addressLowercase],
    async () => {
      const response = await fetch(
        `https://api.ensideas.com/ens/resolve/${addressLowercase}`
      );
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }

      const ensResponse: Promise<ENSResponse> = response.json();
      return ensResponse;
    },
    {
      enabled: Boolean(address),
      placeholderData: placeholder,
    }
  );

  if (!data) {
    return {
      ...placeholder,
      ...ensQuery,
    };
  }

  return {
    ...data,
    ...ensQuery,
  };
}
