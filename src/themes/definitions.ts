import type { HaloTheme, ThemeId } from "../types/themes";

export const THEMES: Record<ThemeId, HaloTheme> = {
  "cyber-blue": {
    id: "cyber-blue",
    name: "Cyber Blue",
    mode: "full-edge",
    working: {
      color: "#00d4ff",
      secondaryColor: "#0066ff",
      durationMs: 2800,
      intensity: 0.78,
      widthPx: 4,
      effect: "flow",
    },
    attention: {
      color: "#ffb700",
      secondaryColor: "#ff6a00",
      durationMs: 1200,
      intensity: 0.82,
      widthPx: 4,
      effect: "pulse",
    },
    completed: {
      color: "#00ff88",
      secondaryColor: "#00cc66",
      durationMs: 2000,
      intensity: 0.9,
      widthPx: 4,
      effect: "sweep",
    },
  },

  sakura: {
    id: "sakura",
    name: "Sakura",
    mode: "full-edge",
    working: {
      color: "#ff6eb4",
      secondaryColor: "#c44dff",
      durationMs: 3000,
      intensity: 0.72,
      widthPx: 4,
      effect: "flow",
    },
    attention: {
      color: "#ff8c69",
      secondaryColor: "#ff6eb4",
      durationMs: 1200,
      intensity: 0.78,
      widthPx: 4,
      effect: "pulse",
    },
    completed: {
      color: "#ffb6d9",
      secondaryColor: "#ffc0cb",
      durationMs: 2000,
      intensity: 0.82,
      widthPx: 4,
      effect: "sweep",
    },
  },

  minimal: {
    id: "minimal",
    name: "Minimal",
    mode: "minimal-bar",
    working: {
      color: "#4a9eff",
      durationMs: 2000,
      intensity: 0.6,
      widthPx: 3,
      effect: "minimal-line",
    },
    attention: {
      color: "#ffb700",
      durationMs: 1200,
      intensity: 0.7,
      widthPx: 3,
      effect: "minimal-line",
    },
    completed: {
      color: "#00cc66",
      durationMs: 2000,
      intensity: 0.7,
      widthPx: 3,
      effect: "minimal-line",
    },
  },
};

export function getTheme(id: ThemeId): HaloTheme {
  return THEMES[id];
}

export function getEffectConfig(theme: HaloTheme, state: "working" | "attention" | "completed") {
  return theme[state];
}
