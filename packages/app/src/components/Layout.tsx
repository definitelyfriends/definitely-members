import styled from "@emotion/styled";
import Link from "next/link";
import { ButtonConnect } from "./ButtonConnect";
import { DefLogo } from "./DefLogo";
import { Mono, Title } from "./Typography";

const Wrapper = styled.div`
  max-width: 48rem;
  min-height: 100%;
  padding: 2rem 1rem;
  margin: 0 auto;
  display: flex;
  flex-direction: column;

  @media (min-width: 32rem) {
    padding: 2rem;
  }
`;

const Main = styled.main`
  flex: 1;
`;

const Header = styled.header`
  display: grid;
  grid-template-columns: 1fr;
  grid-gap: 2em;
  margin-bottom: 3em;

  @media (min-width: 32rem) {
    grid-template-columns: 1fr max-content;
    align-items: center;
  }
`;

const Footer = styled.footer`
  display: flex;
  gap: 1em;
  margin-top: 3em;
`;

interface Props {
  children: React.ReactNode;
}

export function Layout({ children }: Props) {
  return (
    <Wrapper>
      <Main>
        <Header>
          <div>
            <Title>
              <Link href="/">
                <DefLogo aria-label="DEF Memberships" />
              </Link>
            </Title>
            <Mono subdued>Membership NFTs for DEF folks</Mono>
          </div>

          <ButtonConnect />
        </Header>

        {children}
      </Main>

      <Footer>
        <Mono subdued>
          <Link href="https://defdao.xyz">defdao.xyz</Link>
        </Mono>
      </Footer>
    </Wrapper>
  );
}
