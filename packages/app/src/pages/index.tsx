import styled from "@emotion/styled";
import { ClaimCard } from "../components/ClaimCard";
import { DefLogoCard } from "../components/DefLogoCard";
import { InfoCard } from "../components/InfoCard";
import { InviteCard } from "../components/InviteCard";
import { Layout } from "../components/Layout";

const Page = styled.div`
  display: grid;
  grid-template-columns: 1fr;
  grid-gap: 2rem;
`;

export default function HomePage() {
  return (
    <Layout>
      <Page>
        <DefLogoCard />
        <ClaimCard />
        <InviteCard />
        <InfoCard />
      </Page>
    </Layout>
  );
}
