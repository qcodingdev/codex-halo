import type React from "react";
import { getTheme } from "../themes/definitions";
import type { HaloState } from "../types/state";
import type { ThemeId } from "../types/themes";
import { FullEdgeEffect } from "../effects/FullEdgeEffect";
import { MinimalBarEffect } from "../effects/MinimalBarEffect";

interface HaloOverlayProps {
  state: HaloState;
  themeId: ThemeId;
}

export const HaloOverlay: React.FC<HaloOverlayProps> = ({ state, themeId }) => {
  if (state === "idle") {
    return null;
  }

  const theme = getTheme(themeId);

  if (theme.mode === "minimal-bar") {
    return <MinimalBarEffect key={`${themeId}-${state}`} theme={theme} state={state} />;
  }

  return <FullEdgeEffect key={`${themeId}-${state}`} theme={theme} state={state} />;
};
