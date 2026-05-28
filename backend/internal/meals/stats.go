package meals

import (
	"time"
)

const DefaultSessionGap = 30 * time.Minute

type MealLog struct {
	ID       int       `json:"id"`
	UserID   int       `json:"user_id"`
	LoggedAt time.Time `json:"logged_at"`
	Note     *string   `json:"note,omitempty"`
}

type EatingSession struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

type FastingInterval struct {
	Start    time.Time `json:"start"`
	End      time.Time `json:"end"`
	Duration float64   `json:"duration_hours"`
}

type DailyStats struct {
	Date              string  `json:"date"`
	MealCount         int     `json:"meal_count"`
	SessionCount      int     `json:"session_count"`
	TotalEatingHours  float64 `json:"total_eating_hours"`
	LongestFastHours  float64 `json:"longest_fast_hours"`
	CurrentFastHours  float64 `json:"current_fast_hours"`
	TargetEatingHours int     `json:"target_eating_hours"`
	TargetFastHours   int     `json:"target_fast_hours"`
	PlanStatus        string  `json:"plan_status"`
}

type WeeklyStats struct {
	Days              []DailyStats `json:"days"`
	AvgEatingHours    float64      `json:"avg_eating_hours"`
	AvgLongestFast    float64      `json:"avg_longest_fast_hours"`
	DaysOnPlan        int          `json:"days_on_plan"`
	TargetEatingHours int          `json:"target_eating_hours"`
	TargetFastHours   int          `json:"target_fast_hours"`
}

func GroupIntoSessions(meals []MealLog, gap time.Duration) []EatingSession {
	if len(meals) == 0 {
		return nil
	}

	sorted := make([]MealLog, len(meals))
	copy(sorted, meals)
	sortMealsAsc(sorted)

	sessions := []EatingSession{{Start: sorted[0].LoggedAt, End: sorted[0].LoggedAt}}
	for i := 1; i < len(sorted); i++ {
		last := &sessions[len(sessions)-1]
		if sorted[i].LoggedAt.Sub(last.End) <= gap {
			last.End = sorted[i].LoggedAt
			continue
		}
		sessions = append(sessions, EatingSession{Start: sorted[i].LoggedAt, End: sorted[i].LoggedAt})
	}

	return sessions
}

func FastingIntervals(meals []MealLog, gap time.Duration) []FastingInterval {
	sessions := GroupIntoSessions(meals, gap)
	if len(sessions) < 2 {
		return nil
	}

	intervals := make([]FastingInterval, 0, len(sessions)-1)
	for i := 1; i < len(sessions); i++ {
		start := sessions[i-1].End
		end := sessions[i].Start
		duration := end.Sub(start).Hours()
		intervals = append(intervals, FastingInterval{
			Start:    start,
			End:      end,
			Duration: duration,
		})
	}

	return intervals
}

func SessionEatingHours(session EatingSession) float64 {
	d := session.End.Sub(session.Start)
	minDuration := 15 * time.Minute
	if d <= 0 {
		return minDuration.Hours()
	}
	if d < minDuration {
		return minDuration.Hours()
	}
	return d.Hours()
}

func ComputeDailyStats(meals []MealLog, day time.Time, gap time.Duration, targetEating, targetFast int, now time.Time) DailyStats {
	dayStart := startOfDay(day)
	dayEnd := dayStart.Add(24 * time.Hour)

	var dayMeals []MealLog
	for _, m := range meals {
		if !m.LoggedAt.Before(dayStart) && m.LoggedAt.Before(dayEnd) {
			dayMeals = append(dayMeals, m)
		}
	}

	sessions := GroupIntoSessions(dayMeals, gap)
	var totalEating float64
	for _, s := range sessions {
		totalEating += SessionEatingHours(s)
	}

	intervals := FastingIntervals(dayMeals, gap)
	longestFast := 0.0
	for _, iv := range intervals {
		if iv.Duration > longestFast {
			longestFast = iv.Duration
		}
	}

	currentFast := 0.0
	if len(dayMeals) > 0 {
		lastMeal := dayMeals[0]
		for _, m := range dayMeals[1:] {
			if m.LoggedAt.After(lastMeal.LoggedAt) {
				lastMeal = m
			}
		}
		if isSameDay(lastMeal.LoggedAt, day) && isSameDay(now, day) {
			currentFast = now.Sub(lastMeal.LoggedAt).Hours()
		}
	}

	status := planStatus(totalEating, longestFast, currentFast, targetEating, targetFast, len(dayMeals) > 0, isSameDay(now, day))

	return DailyStats{
		Date:              dayStart.Format("2006-01-02"),
		MealCount:         len(dayMeals),
		SessionCount:      len(sessions),
		TotalEatingHours:  round2(totalEating),
		LongestFastHours:  round2(longestFast),
		CurrentFastHours:  round2(currentFast),
		TargetEatingHours: targetEating,
		TargetFastHours:   targetFast,
		PlanStatus:        status,
	}
}

func ComputeWeeklyStats(meals []MealLog, endDay time.Time, gap time.Duration, targetEating, targetFast int, now time.Time) WeeklyStats {
	days := make([]DailyStats, 7)
	var totalEating, totalLongest float64
	onPlan := 0

	for i := 6; i >= 0; i-- {
		day := startOfDay(endDay).AddDate(0, 0, -i)
		stats := ComputeDailyStats(meals, day, gap, targetEating, targetFast, now)
		days[6-i] = stats
		if stats.MealCount > 0 {
			totalEating += stats.TotalEatingHours
			totalLongest += stats.LongestFastHours
			if stats.PlanStatus == "green" {
				onPlan++
			}
		}
	}

	activeDays := 0
	for _, d := range days {
		if d.MealCount > 0 {
			activeDays++
		}
	}

	avgEating := 0.0
	avgLongest := 0.0
	if activeDays > 0 {
		avgEating = totalEating / float64(activeDays)
		avgLongest = totalLongest / float64(activeDays)
	}

	return WeeklyStats{
		Days:              days,
		AvgEatingHours:    round2(avgEating),
		AvgLongestFast:    round2(avgLongest),
		DaysOnPlan:        onPlan,
		TargetEatingHours: targetEating,
		TargetFastHours:   targetFast,
	}
}

func planStatus(eatingHours, longestFast, currentFast float64, targetEating, targetFast int, hasMeals, isToday bool) string {
	if !hasMeals {
		return "gray"
	}

	eatingOK := eatingHours <= float64(targetEating)
	fastOK := longestFast >= float64(targetFast)
	if isToday && currentFast >= float64(targetFast) {
		fastOK = true
	}

	if eatingOK && fastOK {
		return "green"
	}
	if eatingOK || fastOK {
		return "yellow"
	}
	return "red"
}

func sortMealsAsc(meals []MealLog) {
	for i := 0; i < len(meals); i++ {
		for j := i + 1; j < len(meals); j++ {
			if meals[j].LoggedAt.Before(meals[i].LoggedAt) {
				meals[i], meals[j] = meals[j], meals[i]
			}
		}
	}
}

func startOfDay(t time.Time) time.Time {
	y, m, d := t.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, t.Location())
}

func isSameDay(a, b time.Time) bool {
	ay, am, ad := a.Date()
	by, bm, bd := b.Date()
	return ay == by && am == bm && ad == bd
}

func round2(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}

func HoursSinceLastMeal(meals []MealLog, now time.Time) float64 {
	if len(meals) == 0 {
		return 0
	}
	last := meals[0]
	for _, m := range meals[1:] {
		if m.LoggedAt.After(last.LoggedAt) {
			last = m
		}
	}
	return round2(now.Sub(last.LoggedAt).Hours())
}

func LastMealTime(meals []MealLog) *time.Time {
	if len(meals) == 0 {
		return nil
	}
	last := meals[0].LoggedAt
	for _, m := range meals[1:] {
		if m.LoggedAt.After(last) {
			last = m.LoggedAt
		}
	}
	return &last
}
