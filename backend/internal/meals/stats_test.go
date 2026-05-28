package meals

import (
	"testing"
	"time"
)

func TestGroupIntoSessions(t *testing.T) {
	base := time.Date(2026, 5, 28, 8, 0, 0, 0, time.UTC)
	meals := []MealLog{
		{LoggedAt: base},
		{LoggedAt: base.Add(20 * time.Minute)},
		{LoggedAt: base.Add(2 * time.Hour)},
	}

	sessions := GroupIntoSessions(meals, 30*time.Minute)
	if len(sessions) != 2 {
		t.Fatalf("expected 2 sessions, got %d", len(sessions))
	}
	if !sessions[0].Start.Equal(base) || !sessions[0].End.Equal(base.Add(20*time.Minute)) {
		t.Fatalf("unexpected first session: %+v", sessions[0])
	}
}

func TestFastingIntervals(t *testing.T) {
	base := time.Date(2026, 5, 28, 8, 0, 0, 0, time.UTC)
	meals := []MealLog{
		{LoggedAt: base},
		{LoggedAt: base.Add(18 * time.Hour)},
	}

	intervals := FastingIntervals(meals, 30*time.Minute)
	if len(intervals) != 1 {
		t.Fatalf("expected 1 interval, got %d", len(intervals))
	}
	if intervals[0].Duration < 17.9 || intervals[0].Duration > 18.1 {
		t.Fatalf("expected ~18h fast, got %f", intervals[0].Duration)
	}
}

func TestComputeDailyStats_PlanStatus(t *testing.T) {
	day := time.Date(2026, 5, 28, 12, 0, 0, 0, time.UTC)
	base := time.Date(2026, 5, 28, 8, 0, 0, 0, time.UTC)

	meals := []MealLog{
		{LoggedAt: base},
		{LoggedAt: base.Add(15 * time.Minute)},
	}

	stats := ComputeDailyStats(meals, day, 30*time.Minute, 8, 16, day)
	if stats.MealCount != 2 {
		t.Fatalf("expected 2 meals, got %d", stats.MealCount)
	}
	if stats.SessionCount != 1 {
		t.Fatalf("expected 1 session, got %d", stats.SessionCount)
	}
	if stats.PlanStatus == "gray" {
		t.Fatal("expected non-gray status when meals exist")
	}
}

func TestHoursSinceLastMeal(t *testing.T) {
	now := time.Date(2026, 5, 28, 20, 0, 0, 0, time.UTC)
	meals := []MealLog{
		{LoggedAt: now.Add(-5 * time.Hour)},
		{LoggedAt: now.Add(-2 * time.Hour)},
	}

	hours := HoursSinceLastMeal(meals, now)
	if hours < 1.99 || hours > 2.01 {
		t.Fatalf("expected ~2 hours, got %f", hours)
	}
}

func TestComputeWeeklyStats(t *testing.T) {
	endDay := time.Date(2026, 5, 28, 12, 0, 0, 0, time.UTC)
	base := time.Date(2026, 5, 28, 8, 0, 0, 0, time.UTC)
	meals := []MealLog{{LoggedAt: base}}

	stats := ComputeWeeklyStats(meals, endDay, 30*time.Minute, 8, 16, endDay)
	if len(stats.Days) != 7 {
		t.Fatalf("expected 7 days, got %d", len(stats.Days))
	}
}
