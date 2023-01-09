import styled from "@emotion/styled";
import Link from "next/link";
import { useState } from "react";
import { useEtherscan } from "../hooks/useEtherscan";
import { useMembersQuery } from "../hooks/useMembersQuery";
import { MEMBERSHIPS_CONTRACT } from "../utils/contracts";
import { ButtonClear } from "./ButtonClear";
import { Card } from "./Card";
import { ENSAddress } from "./ENSAddress";
import { LoadingIndicator } from "./LoadingIndicator";
import { Mono } from "./Typography";

const List = styled.ul`
  list-style: none;
  padding: 0;
  margin-top: 1rem;
`;

const ListItem = styled.li`
  display: grid;
  grid-template-areas: "id address address" ". block invites";
  grid-template-columns: 1.5rem 1fr 1fr;
  grid-row-gap: 0.25rem;
  grid-column-gap: 0.5rem;

  & + & {
    margin-top: 0.5rem;
    padding-top: 0.5rem;
    border-top: 1px dotted rgba(var(--foreground-alpha), 0.1);
  }

  @media (min-width: 32rem) {
    grid-template-areas: "id address block invites";
    grid-template-columns: 1.5rem 1fr 5rem 3rem;
  }
`;

const IdArea = styled(Mono)`
  grid-area: id;
`;

const AddressArea = styled(Mono)`
  grid-area: address;
`;

const BlockArea = styled(Mono)`
  grid-area: block;
  @media (min-width: 32rem) {
    text-align: right;
  }
`;

const InvitesArea = styled(Mono)`
  grid-area: invites;
  text-align: right;
`;

const SORT_KEY = {
  NONE: "none",
  ADDRESS: "address",
  JOINED_BLOCK: "joined block",
  INVITED_COUNT: "invited count",
} as const;

type SortKey = typeof SORT_KEY[keyof typeof SORT_KEY];

export function MembersCard() {
  const { getAddressUrl, getTransactionUrl } = useEtherscan();
  const { data: members, isLoading } = useMembersQuery();
  const [sortKey, setSortKey] = useState<SortKey>("none");

  let sortedMembers = members;
  if (members) {
    if (sortKey === "address") {
      sortedMembers = members.sort((a, b) =>
        a.address.localeCompare(b.address)
      );
    } else if (sortKey === "joined block") {
      sortedMembers = members.sort(
        (a, b) => a.joinedBlockNumber - b.joinedBlockNumber
      );
    } else if (sortKey === "invited count") {
      sortedMembers = members.sort(
        (a, b) =>
          (b.invited ? b.invited.length : 0) -
          (a.invited ? a.invited.length : 0)
      );
    } else {
      sortedMembers = members.sort(
        (a, b) =>
          (a.tokenId ? parseInt(a.tokenId, 10) : 0) -
          (b.tokenId ? parseInt(b.tokenId, 10) : 0)
      );
    }
  }

  return (
    <Card title="Directory">
      {isLoading && <LoadingIndicator margin="1 0 0" />}
      {!isLoading && (
        <List>
          <ListItem>
            <IdArea uppercase subdued>
              <ButtonClear onClick={() => setSortKey("none")}>#</ButtonClear>
            </IdArea>
            <AddressArea uppercase subdued>
              Address
            </AddressArea>
            <BlockArea uppercase subdued>
              <ButtonClear onClick={() => setSortKey("joined block")}>
                Block
              </ButtonClear>
            </BlockArea>
            <InvitesArea uppercase subdued>
              <ButtonClear onClick={() => setSortKey("invited count")}>
                Inv.
              </ButtonClear>
            </InvitesArea>
          </ListItem>
          {sortedMembers &&
            sortedMembers.map((member) => (
              <ListItem key={member.id}>
                <IdArea subdued>
                  <Link
                    href={`https://opensea.io/assets/${MEMBERSHIPS_CONTRACT.address}/${member.tokenId}`}
                  >
                    {member.tokenId}
                  </Link>
                </IdArea>
                <AddressArea>
                  <Link href={getAddressUrl(member.address) || ""}>
                    <ENSAddress address={member.address} />
                  </Link>
                </AddressArea>
                <BlockArea>
                  <Link href={getTransactionUrl(member.joinedTxHash) || ""}>
                    {member.joinedBlockNumber}
                  </Link>
                </BlockArea>
                <InvitesArea
                  subdued={!member.invited || member.invited.length === 0}
                >
                  {(member.invited && member.invited.length) || 0}
                </InvitesArea>
              </ListItem>
            ))}
        </List>
      )}
    </Card>
  );
}
