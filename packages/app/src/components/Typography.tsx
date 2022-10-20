import { css } from "@emotion/react";
import styled from "@emotion/styled";
import withMargin, { WithMarginProp } from "./withMargin";

interface BaseTextProps extends WithMarginProp {
  subdued?: boolean;
  size?: "small" | "large";
}

export const subdued = css`
  opacity: 0.48;
`;

export const titleStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-style: italic;
  font-size: 3.2em;
`;

export const Title = styled.h1<BaseTextProps>`
  ${titleStyles};
  ${(p) => p.subdued && subdued};
  ${withMargin};
`;

export const headingStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-style: italic;
  font-size: 2.4em;
`;

export const Heading = styled.h2<BaseTextProps>`
  ${headingStyles};
  ${(p) => p.subdued && subdued};
  ${withMargin};
`;

export const subheadingStyles = css`
  font-family: var(--font-heading);
  font-weight: bold;
  font-style: italic;
  font-size: 1.6em;
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
          font-size: 0.75em;
        `;
      case "large":
        return css`
          font-size: 1.6em;
        `;
      default:
        break;
    }
  }}
  & + & {
    margin-top: 0.5em;
  }
  ${withMargin};
`;

export const monoStyles = css`
  font-family: var(--font-mono);
  font-size: 0.875em;
  text-transform: uppercase;
`;

export const Mono = styled.p<BaseTextProps>`
  ${monoStyles};
  ${(p) => p.subdued && subdued};
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
