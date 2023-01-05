import { css } from "@emotion/react";
import styled from "@emotion/styled";
import withMargin, { WithMarginProp } from "./withMargin";

interface BaseTextProps extends WithMarginProp {
  subdued?: boolean;
  uppercase?: boolean;
  size?: "small" | "large";
}

export const subdued = css`
  opacity: 0.48;
`;

export const uppercase = css`
  text-transform: uppercase;
`;

export const titleStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-size: 2em;
  a {
    text-decoration: none;
  }
`;

export const Title = styled.h1<BaseTextProps>`
  ${titleStyles};
  ${(p) => p.subdued && subdued};
  ${withMargin};
`;

export const headingStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-size: 1.6em;
`;

export const Heading = styled.h2<BaseTextProps>`
  ${headingStyles};
  ${(p) => p.subdued && subdued};
  ${withMargin};
`;

export const subheadingStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-size: 1.2em;
`;

export const Subheading = styled.h3<BaseTextProps>`
  ${subheadingStyles};
  ${(p) => p.subdued && subdued};
  ${withMargin};
`;

export const bodyStyles = css`
  margin: 0;
  font-family: var(--font-sans);
  font-size: 1em;
`;

export const Body = styled.p<BaseTextProps>`
  ${bodyStyles};
  ${(p) => p.subdued && subdued};
  ${(p) => {
    switch (p.size) {
      case "small":
        return css`
          font-size: 0.75rem;
        `;
      case "large":
        return css`
          font-size: 1.6rem;
        `;
      default:
        break;
    }
  }}
  ${withMargin};
`;

export const monoStyles = css`
  font-family: var(--font-mono);
  font-size: 0.875rem;
`;

export const Mono = styled.p<BaseTextProps>`
  ${monoStyles};
  ${(p) => p.subdued && subdued};
  ${(p) => p.uppercase && uppercase};
  ${(p) => {
    switch (p.size) {
      case "small":
        return css`
          font-size: 0.7em;
        `;
      default:
        break;
    }
  }}
  ${withMargin};
`;
