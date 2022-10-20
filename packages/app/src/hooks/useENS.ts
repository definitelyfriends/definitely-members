import { useQuery } from "@tanstack/react-query";

function addressDisplayName(address?: string) {
  if (!address) return "";
  const match = address.match(
    /^(0x[a-zA-Z0-9]{3})[a-zA-Z0-9]+([a-zA-Z0-9]{4})$/
  );
  if (!match) return address;
  return `${match[1]}…${match[2]}`;
}

export function useENS(address?: string) {
  const addressLowercase = address && address.toLowerCase();

  const { data, ...ensQuery } = useQuery(
    ["ensResolver", addressLowercase],
    async () => {
      const response = await fetch(
        `https://api.ensideas.com/ens/resolve/${addressLowercase}`
      );
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      return response.json();
    },
    {
      enabled: Boolean(address),
      placeholderData: {
        address: addressLowercase,
        name: null,
        displayName: addressDisplayName(addressLowercase),
        avatar: null,
      },
    }
  );

  return {
    address: data.address,
    name: data.name,
    displayName: data.displayName,
    avatar: data.avatar,
    ensQuery,
  };
}
