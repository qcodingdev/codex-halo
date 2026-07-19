import { type EffectConfig } from "../types/themes";

/**
 * Generate CSS custom properties for an effect config.
 */
export function getEffectVars(config: EffectConfig): Record<string, string> {
  return {
    "--halo-color": config.color,
    "--halo-color-secondary": config.secondaryColor || config.color,
    "--halo-width": `${config.widthPx}px`,
    "--halo-duration": `${config.durationMs}ms`,
    "--halo-intensity": String(config.intensity),
    // Keep the light legible on Retina displays without animating expensive
    // layout properties; only the four edge strips are composited.
    "--halo-glow": `${Math.max(30, Math.round(38 * config.intensity))}px`,
  };
}
