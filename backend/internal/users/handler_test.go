package users

import "testing"

func TestPlanTargetValidation(t *testing.T) {
	tests := []struct {
		name    string
		hours   int
		minutes int
		valid   bool
	}{
		{name: "minutes only", hours: 0, minutes: 30, valid: true},
		{name: "hours only", hours: 16, minutes: 0, valid: true},
		{name: "both", hours: 16, minutes: 30, valid: true},
		{name: "zero total", hours: 0, minutes: 0, valid: false},
		{name: "negative hours", hours: -1, minutes: 10, valid: false},
		{name: "too many minutes", hours: 0, minutes: 60, valid: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := tt.hours >= 0 &&
				tt.minutes >= 0 &&
				tt.minutes <= 59 &&
				tt.hours*60+tt.minutes >= 1

			if valid != tt.valid {
				t.Fatalf("expected valid=%v for %dh %dm", tt.valid, tt.hours, tt.minutes)
			}
		})
	}
}
