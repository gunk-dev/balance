export interface Metric {
  id: string;
  name: string;
  leftLabel: string;
  rightLabel: string;
  steps: number;
  schedule?: string[]; // notification times ["09:00", "13:00", "18:00"]
  order: number; // display order
  enabled: boolean; // user can disable without deleting
}

export interface LogEntry {
  id: string;
  metricId: string;
  value: number;
  timestamp: number;
  synced: boolean; // has this been synced to remote?
}

// Deferred — kept in types for future food logging with AI image analysis
export interface FoodLogEntry {
  id: string;
  timestamp: number;
  imageUrl: string;
  calories: number;
  dairy: boolean;
  carb: string;
  gluten: boolean;
  meat: string;
}
