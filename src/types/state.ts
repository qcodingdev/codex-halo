export type HaloState = "idle" | "working" | "attention" | "completed";

export interface StateFile {
  state: string;
  updatedAt: number;
  sessionId?: string;
  event?: string;
}

export interface HaloStateEvent {
  state: HaloState;
  updatedAt: number;
  sessionId?: string;
  event?: string;
}
