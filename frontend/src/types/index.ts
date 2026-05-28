export interface AuthResponse {
  token: string
  username: string
  user_id: number
}

export interface PlanSettings {
  plan_type: string
  eating_hours: number
  fasting_hours: number
  fasting_minutes: number
}

export interface MealLog {
  id: number
  user_id: number
  logged_at: string
  note?: string
}

export interface DailyStats {
  date: string
  meal_count: number
  session_count: number
  total_eating_hours: number
  longest_fast_hours: number
  current_fast_hours: number
  target_eating_hours: number
  target_fast_hours: number
  plan_status: 'green' | 'yellow' | 'red' | 'gray'
}

export interface WeeklyStats {
  days: DailyStats[]
  avg_eating_hours: number
  avg_longest_fast_hours: number
  days_on_plan: number
  target_eating_hours: number
  target_fast_hours: number
}

export interface CurrentState {
  hours_since_last_meal: number
  last_meal_at: string | null
  today: DailyStats
}

export const DEFAULT_PLAN: PlanSettings = {
  plan_type: 'custom',
  eating_hours: 8,
  fasting_hours: 16,
  fasting_minutes: 0,
}
