import type { ThemeId } from "./themes";

export interface AppSettings {
  enabled: boolean;
  theme: ThemeId;
  startAtLogin: boolean;
}
