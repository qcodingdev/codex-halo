import { useEffect, useState } from "react";
import type { HaloState } from "../types/state";
import type { ThemeId } from "../types/themes";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";

interface StateManager {
  currentState: HaloState;
  theme: ThemeId;
}

const HALO_STATES: readonly HaloState[] = ["idle", "working", "attention", "completed"];
const THEME_IDS: readonly ThemeId[] = ["cyber-blue", "sakura", "minimal"];

function isHaloState(value: unknown): value is HaloState {
  return typeof value === "string" && HALO_STATES.includes(value as HaloState);
}

function isThemeId(value: unknown): value is ThemeId {
  return typeof value === "string" && THEME_IDS.includes(value as ThemeId);
}

function isTauriRuntime(): boolean {
  return "__TAURI_INTERNALS__" in window;
}

function previewState(): HaloState {
  const value = new URLSearchParams(window.location.search).get("state");
  return isHaloState(value) ? value : "idle";
}

function previewTheme(): ThemeId {
  const value = new URLSearchParams(window.location.search).get("theme");
  return isThemeId(value) ? value : "cyber-blue";
}

export function useStateManager(): StateManager {
  const [currentState, setCurrentState] = useState<HaloState>(() =>
    isTauriRuntime() ? "idle" : previewState(),
  );
  const [theme, setThemeState] = useState<ThemeId>(() =>
    isTauriRuntime() ? "cyber-blue" : previewTheme(),
  );

  useEffect(() => {
    if (!isTauriRuntime()) {
      return;
    }

    let disposed = false;
    const cleanups: Array<() => void> = [];

    void Promise.all([
      listen<{ state?: unknown }>("halo-state", (event) => {
        if (isHaloState(event.payload.state)) setCurrentState(event.payload.state);
      }),
      listen<{ theme?: unknown }>("halo-theme", (event) => {
        if (isThemeId(event.payload.theme)) setThemeState(event.payload.theme);
      }),
    ]).then((unlisteners) => {
      if (disposed) {
        unlisteners.forEach((unlisten) => unlisten());
      } else {
        cleanups.push(...unlisteners);
      }
    });

    void Promise.all([invoke("get_state"), invoke("get_settings")])
      .then(([stateValue, settingsValue]) => {
        if (disposed) return;
        if (isHaloState(stateValue)) setCurrentState(stateValue);
        const settings = settingsValue as { enabled?: unknown; theme?: unknown };
        if (settings.enabled === false) setCurrentState("idle");
        if (isThemeId(settings.theme)) setThemeState(settings.theme);
      });

    return () => {
      disposed = true;
      cleanups.forEach((cleanup) => cleanup());
    };
  }, []);

  return { currentState, theme };
}
