import { css } from "@emotion/react";

export interface WithMarginProp {
  margin?: string;
}

const sizes = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 3, 4, 6, 8, 12, 16];

export default function withMargin({ margin = "" }: WithMarginProp) {
  const trimmedMargin = margin.trim();

  if (!trimmedMargin) {
    return "";
  }

  const margins: string[] = trimmedMargin
    .split(" ")
    .filter(Boolean)
    .map((sizeStr: string) => {
      if (!sizeStr) return "";

      let size = sizeStr.trim();
      let isNegative = false;

      if (size.startsWith("-") && size.split("-").length > 1) {
        isNegative = true;
        size = size.split("-")[1];
      }

      if (sizes.map((i) => i.toString()).includes(size)) {
        return isNegative ? `-${size}em` : `${size}em`;
      } else if (size === "0") {
        return "0";
      } else if (size === "auto") {
        return "auto";
      } else {
        return "";
      }
    });

  switch (margins.slice(0, 4).length) {
    case 1:
      return css`
        margin: ${margins[0]};
      `;
    case 2:
      return css`
        margin: ${margins[0]} ${margins[1]};
      `;
    case 3:
      return css`
        margin: ${margins[0]} ${margins[1]} ${margins[2]};
      `;
    case 4:
      return css`
        margin: ${margins[0]} ${margins[1]} ${margins[2]} ${margins[3]};
      `;
    default:
      return css`
        margin: 0;
      `;
  }
}
