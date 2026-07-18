export type ThemeId = "cyber-blue" | "sakura" | "minimal";

export interface EffectConfig {
  color: string;
  secondaryColor?: string;
  durationMs: number;
  intensity: number;
  widthPx: number;
  effect: "flow" | "pulse" | "sweep" | "minimal-line";
}

export interface HaloTheme {
  id: ThemeId;
  name: string;
  mode: "full-edge" | "minimal-bar";
  working: EffectConfig;
  attention: EffectConfig;
  completed: EffectConfig;
}
