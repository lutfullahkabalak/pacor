package meals

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/auth"
)

type Handler struct {
	repo           *Repository
	sessionGapMins int
}

func NewHandler(repo *Repository, sessionGapMins int) *Handler {
	return &Handler{repo: repo, sessionGapMins: sessionGapMins}
}

type createMealRequest struct {
	LoggedAt *time.Time `json:"logged_at"`
	Note     *string    `json:"note"`
}

type currentStateResponse struct {
	HoursSinceLastMeal float64    `json:"hours_since_last_meal"`
	LastMealAt         *time.Time `json:"last_meal_at"`
	Today              DailyStats `json:"today"`
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	var req createMealRequest
	if r.Body != nil {
		_ = json.NewDecoder(r.Body).Decode(&req)
	}

	loggedAt := time.Now().UTC()
	if req.LoggedAt != nil {
		loggedAt = req.LoggedAt.UTC()
	}

	meal, err := h.repo.Create(r.Context(), user.ID, loggedAt, req.Note)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "yemek kaydedilemedi")
		return
	}

	writeJSON(w, http.StatusCreated, meal)
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	from, to, err := parseRange(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz tarih araligi")
		return
	}

	meals, err := h.repo.List(r.Context(), user.ID, from, to)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "kayitlar alinamadi")
		return
	}

	if meals == nil {
		meals = []MealLog{}
	}

	writeJSON(w, http.StatusOK, meals)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	mealID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz id")
		return
	}

	if err := h.repo.Delete(r.Context(), user.ID, mealID); err != nil {
		if err == ErrNotFound {
			writeError(w, http.StatusNotFound, "kayit bulunamadi")
			return
		}
		writeError(w, http.StatusInternalServerError, "kayit silinemedi")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) DailyStats(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	now := time.Now()
	day := now
	if q := r.URL.Query().Get("date"); q != "" {
		parsed, err := time.Parse("2006-01-02", q)
		if err != nil {
			writeError(w, http.StatusBadRequest, "gecersiz tarih")
			return
		}
		day = parsed
	}

	stats, err := h.computeDailyForUser(r, user.ID, day, now)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "istatistik alinamadi")
		return
	}

	writeJSON(w, http.StatusOK, stats)
}

func (h *Handler) WeeklyStats(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	now := time.Now()
	endDay := now
	if q := r.URL.Query().Get("end"); q != "" {
		parsed, err := time.Parse("2006-01-02", q)
		if err != nil {
			writeError(w, http.StatusBadRequest, "gecersiz tarih")
			return
		}
		endDay = parsed
	}

	eating, fasting, err := h.repo.GetPlanTargets(r.Context(), user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "plan alinamadi")
		return
	}

	from := startOfDay(endDay).AddDate(0, 0, -6)
	to := startOfDay(endDay).AddDate(0, 0, 1)
	meals, err := h.repo.List(r.Context(), user.ID, from, to)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "kayitlar alinamadi")
		return
	}

	gap := time.Duration(h.sessionGapMins) * time.Minute
	stats := ComputeWeeklyStats(meals, endDay, gap, eating, fasting, now)
	writeJSON(w, http.StatusOK, stats)
}

func (h *Handler) CurrentState(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	now := time.Now()
	recent, err := h.repo.GetRecent(r.Context(), user.ID, 500)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "durum alinamadi")
		return
	}

	todayStats, err := h.computeDailyForUser(r, user.ID, now, now)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "istatistik alinamadi")
		return
	}

	writeJSON(w, http.StatusOK, currentStateResponse{
		HoursSinceLastMeal: HoursSinceLastMeal(recent, now),
		LastMealAt:         LastMealTime(recent),
		Today:              todayStats,
	})
}

func (h *Handler) computeDailyForUser(r *http.Request, userID int, day, now time.Time) (DailyStats, error) {
	eating, fasting, err := h.repo.GetPlanTargets(r.Context(), userID)
	if err != nil {
		return DailyStats{}, err
	}

	from := startOfDay(day).AddDate(0, 0, -1)
	to := startOfDay(day).AddDate(0, 0, 2)
	meals, err := h.repo.List(r.Context(), userID, from, to)
	if err != nil {
		return DailyStats{}, err
	}

	gap := time.Duration(h.sessionGapMins) * time.Minute
	return ComputeDailyStats(meals, day, gap, eating, fasting, now), nil
}

func parseRange(r *http.Request) (time.Time, time.Time, error) {
	now := time.Now()
	from := startOfDay(now).AddDate(0, 0, -30)
	to := startOfDay(now).AddDate(0, 0, 1)

	if q := r.URL.Query().Get("from"); q != "" {
		parsed, err := time.Parse("2006-01-02", q)
		if err != nil {
			return time.Time{}, time.Time{}, err
		}
		from = startOfDay(parsed)
	}
	if q := r.URL.Query().Get("to"); q != "" {
		parsed, err := time.Parse("2006-01-02", q)
		if err != nil {
			return time.Time{}, time.Time{}, err
		}
		to = startOfDay(parsed).AddDate(0, 0, 1)
	}

	return from, to, nil
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
