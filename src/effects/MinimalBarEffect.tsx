import type React from "react";
import type { HaloTheme } from "../types/themes";
import { getEffectVars } from "./effectStyles";

interface MinimalBarEffectProps {
  theme: HaloTheme;
  state: "working" | "attention" | "completed";
}

/**
 * Minimal bar effect: a thin status line at the top center of the screen.
 */
export const MinimalBarEffect: React.FC<MinimalBarEffectProps> = ({ theme, state }) => {
  const config = theme[state];
  const vars = getEffectVars(config);

  return (
    <div className={`halo-minimal halo-minimal-${state}`}>
      <div
        className="halo-minimal-bar"
        style={vars as React.CSSProperties}
      />
    </div>
  );
};
