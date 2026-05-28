package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port           string
	DatabaseURL    string
	JWTSecret      string
	JWTExpiry      time.Duration
	SessionGapMins int
}

func Load() Config {
	jwtHours := 168 // 7 days
	if v := os.Getenv("JWT_EXPIRY_HOURS"); v != "" {
		if h, err := strconv.Atoi(v); err == nil {
			jwtHours = h
		}
	}

	gapMins := 30
	if v := os.Getenv("SESSION_GAP_MINUTES"); v != "" {
		if m, err := strconv.Atoi(v); err == nil {
			gapMins = m
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://oruc:oruc@localhost:5432/oruc?sslmode=disable"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "dev-secret-change-in-production"
	}

	return Config{
		Port:           port,
		DatabaseURL:    dbURL,
		JWTSecret:      jwtSecret,
		JWTExpiry:      time.Duration(jwtHours) * time.Hour,
		SessionGapMins: gapMins,
	}
}
