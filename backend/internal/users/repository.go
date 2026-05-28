package users

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrUserExists         = errors.New("kullanici zaten mevcut")
	ErrInvalidCredentials = errors.New("gecersiz kullanici adi veya pin")
	ErrInvalidPIN         = errors.New("pin en az 4 hane olmali")
	ErrWrongPIN           = errors.New("mevcut pin hatali")
)

type User struct {
	ID        int       `json:"id"`
	Username  string    `json:"username"`
	CreatedAt time.Time `json:"created_at"`
}

type PlanSettings struct {
	PlanType        string `json:"plan_type"`
	EatingHours     int    `json:"eating_hours"`
	FastingHours    int    `json:"fasting_hours"`
	FastingMinutes  int    `json:"fasting_minutes"`
}

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) Register(ctx context.Context, username, pin string) (User, error) {
	if len(pin) < 4 {
		return User{}, ErrInvalidPIN
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)
	if err != nil {
		return User{}, err
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return User{}, err
	}
	defer tx.Rollback(ctx)

	var user User
	err = tx.QueryRow(ctx, `
		INSERT INTO users (username, pin_hash)
		VALUES ($1, $2)
		RETURNING id, username, created_at
	`, username, string(hash)).Scan(&user.ID, &user.Username, &user.CreatedAt)
	if err != nil {
		if isUniqueViolation(err) {
			return User{}, ErrUserExists
		}
		return User{}, err
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO user_settings (user_id, plan_type, eating_hours, fasting_hours, fasting_minutes)
		VALUES ($1, 'custom', 8, 16, 0)
	`, user.ID)
	if err != nil {
		return User{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return User{}, err
	}

	return user, nil
}

func (r *Repository) Login(ctx context.Context, username, pin string) (User, error) {
	var user User
	var pinHash string

	err := r.pool.QueryRow(ctx, `
		SELECT id, username, pin_hash, created_at
		FROM users WHERE username = $1
	`, username).Scan(&user.ID, &user.Username, &pinHash, &user.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, ErrInvalidCredentials
		}
		return User{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(pinHash), []byte(pin)); err != nil {
		return User{}, ErrInvalidCredentials
	}

	return user, nil
}

func (r *Repository) GetPlan(ctx context.Context, userID int) (PlanSettings, error) {
	var plan PlanSettings
	err := r.pool.QueryRow(ctx, `
		SELECT plan_type, eating_hours, fasting_hours, COALESCE(fasting_minutes, 0)
		FROM user_settings WHERE user_id = $1
	`, userID).Scan(&plan.PlanType, &plan.EatingHours, &plan.FastingHours, &plan.FastingMinutes)
	return plan, err
}

func (r *Repository) UpdatePlan(ctx context.Context, userID int, plan PlanSettings) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE user_settings
		SET plan_type = $2, eating_hours = $3, fasting_hours = $4, fasting_minutes = $5, updated_at = NOW()
		WHERE user_id = $1
	`, userID, plan.PlanType, plan.EatingHours, plan.FastingHours, plan.FastingMinutes)
	return err
}

func (r *Repository) UpdatePIN(ctx context.Context, userID int, currentPIN, newPIN string) error {
	if len(newPIN) < 4 {
		return ErrInvalidPIN
	}

	var pinHash string
	err := r.pool.QueryRow(ctx, `
		SELECT pin_hash FROM users WHERE id = $1
	`, userID).Scan(&pinHash)
	if err != nil {
		return err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(pinHash), []byte(currentPIN)); err != nil {
		return ErrWrongPIN
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(newPIN), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	_, err = r.pool.Exec(ctx, `
		UPDATE users SET pin_hash = $2 WHERE id = $1
	`, userID, string(hash))
	return err
}

func isUniqueViolation(err error) bool {
	return err != nil && (contains(err.Error(), "duplicate key") || contains(err.Error(), "unique constraint"))
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || len(sub) == 0 || indexOf(s, sub) >= 0)
}

func indexOf(s, sub string) int {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return i
		}
	}
	return -1
}
