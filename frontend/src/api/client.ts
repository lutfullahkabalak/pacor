const API_URL = import.meta.env.PROD
  ? ''
  : (import.meta.env.VITE_API_URL || 'http://localhost:8080')

class ApiError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

function getToken(): string | null {
  return localStorage.getItem('token')
}

export function setToken(token: string | null) {
  if (token) {
    localStorage.setItem('token', token)
  } else {
    localStorage.removeItem('token')
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> | undefined),
  }

  const token = getToken()
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  })

  if (res.status === 204) {
    return undefined as T
  }

  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    throw new ApiError(res.status, data.error || 'Bir hata oluştu')
  }

  return data as T
}

export const api = {
  register: (username: string, pin: string) =>
    request<import('../types').AuthResponse>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify({ username, pin }),
    }),

  login: (username: string, pin: string) =>
    request<import('../types').AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, pin }),
    }),

  logMeal: () =>
    request<import('../types').MealLog>('/api/meals/', {
      method: 'POST',
      body: JSON.stringify({}),
    }),

  getMeals: (from?: string, to?: string) => {
    const params = new URLSearchParams()
    if (from) params.set('from', from)
    if (to) params.set('to', to)
    const q = params.toString()
    return request<import('../types').MealLog[]>(`/api/meals${q ? `?${q}` : ''}`)
  },

  deleteMeal: (id: number) =>
    request<void>(`/api/meals/${id}`, { method: 'DELETE' }),

  getDailyStats: (date?: string) => {
    const q = date ? `?date=${date}` : ''
    return request<import('../types').DailyStats>(`/api/stats/daily${q}`)
  },

  getWeeklyStats: (end?: string) => {
    const q = end ? `?end=${end}` : ''
    return request<import('../types').WeeklyStats>(`/api/stats/weekly${q}`)
  },

  getCurrentState: () =>
    request<import('../types').CurrentState>('/api/state'),

  getPlan: () =>
    request<import('../types').PlanSettings>('/api/settings/plan'),

  updatePlan: (plan: import('../types').PlanSettings) =>
    request<import('../types').PlanSettings>('/api/settings/plan', {
      method: 'PUT',
      body: JSON.stringify(plan),
    }),

  changePin: (currentPin: string, newPin: string) =>
    request<void>('/api/settings/pin', {
      method: 'PUT',
      body: JSON.stringify({ current_pin: currentPin, new_pin: newPin }),
    }),
}

export { ApiError }
