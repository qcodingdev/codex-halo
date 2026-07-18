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
      {state === "working" && (
        <div className="halo-activation" aria-hidden="true">
          <svg viewBox="0 0 128 128" className="halo-activation-mark">
            <defs>
              <linearGradient id="activation-halo" x1="20" y1="108" x2="110" y2="20">
                <stop stopColor="var(--halo-color)" />
                <stop offset="0.58" stopColor="var(--halo-color-secondary)" />
                <stop offset="1" stopColor="#d8ffff" />
              </linearGradient>
            </defs>
            <circle cx="64" cy="64" r="44" className="halo-activation-ring" />
            <path d="m42 51 15 13-15 13M66 77h25" className="halo-activation-code" />
            <circle cx="94" cy="34" r="3.5" className="halo-activation-spark" />
          </svg>
        </div>
      )}
      {(["top", "right", "bottom", "left"] as const).map((edge) => (
        <div className={`halo-edge halo-edge-${edge}`} key={edge}>
          <span className="halo-edge-light" />
        </div>
      ))}
    </div>
  );
};
