import styled from "@emotion/styled";
import Link from "next/link";
import { useEtherscan } from "../hooks/useEtherscan";
import { CLAIMABLE_ROOT } from "../utils/constants";
import {
  CLAIMABLE_CONTRACT,
  INVITES_CONTRACT,
  MEMBERSHIPS_CONTRACT,
} from "../utils/contracts";
import { Card } from "./Card";
import { Mono } from "./Typography";

const List = styled.ul`
  padding: 0 0 0 1.5em;
`;

export function InfoCard() {
  const { getAddressUrl } = useEtherscan();

  return (
    <Card title="Links">
      <List>
        <li>
          <Mono>
            <Link href="https://opensea.io/collection/def-memberships">
              OpenSea
            </Link>
          </Mono>
        </li>
        <li>
          <Mono>
            <Link href={getAddressUrl(MEMBERSHIPS_CONTRACT.address) || ""}>
              Memberships Contract
            </Link>
          </Mono>
        </li>
        <li>
          <Mono>
            <Link href={getAddressUrl(CLAIMABLE_CONTRACT.address) || ""}>
              Claiming Contract
            </Link>
          </Mono>
        </li>
        <li>
          <Mono>
            <Link
              href={`https://lanyard.org/api/v1/tree?root=${CLAIMABLE_ROOT}`}
            >
              Claiming merkle root
            </Link>
          </Mono>
        </li>
        <li>
          <Mono>
            <Link href={getAddressUrl(INVITES_CONTRACT.address) || ""}>
              Invites Contract
            </Link>
          </Mono>
        </li>
      </List>
    </Card>
  );
}
