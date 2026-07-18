import type React from "react";
import type { HaloTheme } from "../types/themes";
import { getEffectVars } from "./effectStyles";

interface FullEdgeEffectProps {
  theme: HaloTheme;
  state: "working" | "attention" | "completed";
}

/**
 * Full-edge light effect: renders glowing borders around the entire screen.
 */
export const FullEdgeEffect: React.FC<FullEdgeEffectProps> = ({ theme, state }) => {
  const config = theme[state];
  const vars = getEffectVars(config);

  return (
    <div
      className={`halo-frame halo-frame-${state}`}
      style={vars as React.CSSProperties}
    >
      {(["top", "right", "bottom", "left"] as const).map((edge) => (
        <div className={`halo-edge halo-edge-${edge}`} key={edge}>
          <span className="halo-edge-light" />
        </div>
      ))}
    </div>
  );
};
