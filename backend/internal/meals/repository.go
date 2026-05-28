package meals

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotFound = errors.New("kayit bulunamadi")

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) Create(ctx context.Context, userID int, loggedAt time.Time, note *string) (MealLog, error) {
	var meal MealLog
	err := r.pool.QueryRow(ctx, `
		INSERT INTO meal_logs (user_id, logged_at, note)
		VALUES ($1, $2, $3)
		RETURNING id, user_id, logged_at, note
	`, userID, loggedAt, note).Scan(&meal.ID, &meal.UserID, &meal.LoggedAt, &meal.Note)
	return meal, err
}

func (r *Repository) List(ctx context.Context, userID int, from, to time.Time) ([]MealLog, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, logged_at, note
		FROM meal_logs
		WHERE user_id = $1 AND logged_at >= $2 AND logged_at < $3
		ORDER BY logged_at ASC
	`, userID, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []MealLog
	for rows.Next() {
		var m MealLog
		if err := rows.Scan(&m.ID, &m.UserID, &m.LoggedAt, &m.Note); err != nil {
			return nil, err
		}
		meals = append(meals, m)
	}
	return meals, rows.Err()
}

func (r *Repository) Delete(ctx context.Context, userID, mealID int) error {
	tag, err := r.pool.Exec(ctx, `
		DELETE FROM meal_logs WHERE id = $1 AND user_id = $2
	`, mealID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *Repository) GetRecent(ctx context.Context, userID int, limit int) ([]MealLog, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, logged_at, note
		FROM meal_logs
		WHERE user_id = $1
		ORDER BY logged_at DESC
		LIMIT $2
	`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []MealLog
	for rows.Next() {
		var m MealLog
		if err := rows.Scan(&m.ID, &m.UserID, &m.LoggedAt, &m.Note); err != nil {
			return nil, err
		}
		meals = append(meals, m)
	}
	return meals, rows.Err()
}

func (r *Repository) GetPlanTargets(ctx context.Context, userID int) (eating, fasting int, err error) {
	err = r.pool.QueryRow(ctx, `
		SELECT eating_hours, fasting_hours FROM user_settings WHERE user_id = $1
	`, userID).Scan(&eating, &fasting)
	if errors.Is(err, pgx.ErrNoRows) {
		return 8, 16, nil
	}
	return eating, fasting, err
}
