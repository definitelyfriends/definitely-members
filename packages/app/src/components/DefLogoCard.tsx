import styled from "@emotion/styled";
import Image from "next/image";

const Card = styled.div`
  line-height: 0;
  background: black;
  text-align: center;
  border: 1px solid rgba(var(--foreground-alpha), 0.05);
  overflow: hidden;
  padding: 1rem;
  border-radius: 0.5rem;

  @media (min-width: 32rem) {
    padding: 2rem;
    border-radius: 1rem;
  }

  img {
    max-width: 256px;
    width: 100%;
    height: auto;
    overflow: hidden;
  }
`;

export function DefLogoCard() {
  return (
    <Card>
      <Image src="/def-glitch.gif" alt="" width={500} height={500} priority />
    </Card>
  );
}
