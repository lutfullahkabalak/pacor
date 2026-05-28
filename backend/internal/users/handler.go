package users

import (
	"encoding/json"
	"net/http"

	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/auth"
)

type Handler struct {
	repo          *Repository
	generateToken func(userID int, username string) (string, error)
}

func NewHandler(repo *Repository, tokenGen func(int, string) (string, error)) *Handler {
	return &Handler{
		repo:          repo,
		generateToken: tokenGen,
	}
}

type authRequest struct {
	Username string `json:"username"`
	PIN      string `json:"pin"`
}

type authResponse struct {
	Token    string `json:"token"`
	Username string `json:"username"`
	UserID   int    `json:"user_id"`
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz istek")
		return
	}

	if req.Username == "" || req.PIN == "" {
		writeError(w, http.StatusBadRequest, "kullanici adi ve pin gerekli")
		return
	}

	user, err := h.repo.Register(r.Context(), req.Username, req.PIN)
	if err != nil {
		switch err {
		case ErrUserExists:
			writeError(w, http.StatusConflict, "kullanici zaten mevcut")
		case ErrInvalidPIN:
			writeError(w, http.StatusBadRequest, "pin en az 4 hane olmali")
		default:
			writeError(w, http.StatusInternalServerError, "kayit basarisiz")
		}
		return
	}

	token, err := h.generateToken(user.ID, user.Username)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "token olusturulamadi")
		return
	}

	writeJSON(w, http.StatusCreated, authResponse{
		Token:    token,
		Username: user.Username,
		UserID:   user.ID,
	})
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz istek")
		return
	}

	user, err := h.repo.Login(r.Context(), req.Username, req.PIN)
	if err != nil {
		if err == ErrInvalidCredentials {
			writeError(w, http.StatusUnauthorized, "gecersiz kullanici adi veya pin")
			return
		}
		writeError(w, http.StatusInternalServerError, "giris basarisiz")
		return
	}

	token, err := h.generateToken(user.ID, user.Username)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "token olusturulamadi")
		return
	}

	writeJSON(w, http.StatusOK, authResponse{
		Token:    token,
		Username: user.Username,
		UserID:   user.ID,
	})
}

func (h *Handler) GetPlan(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	plan, err := h.repo.GetPlan(r.Context(), user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "plan alinamadi")
		return
	}

	writeJSON(w, http.StatusOK, plan)
}

func (h *Handler) UpdatePlan(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	var plan PlanSettings
	if err := json.NewDecoder(r.Body).Decode(&plan); err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz istek")
		return
	}

	if plan.FastingHours < 0 {
		writeError(w, http.StatusBadRequest, "oruc saati negatif olamaz")
		return
	}
	if plan.FastingMinutes < 0 || plan.FastingMinutes > 59 {
		writeError(w, http.StatusBadRequest, "oruc dakikasi 0-59 arasinda olmali")
		return
	}
	if plan.FastingHours*60+plan.FastingMinutes < 1 {
		writeError(w, http.StatusBadRequest, "hedef en az 1 dakika olmali")
		return
	}

	plan.PlanType = "custom"
	plan.EatingHours = 24 - plan.FastingHours
	if plan.EatingHours <= 0 {
		plan.EatingHours = 1
	}

	if err := h.repo.UpdatePlan(r.Context(), user.ID, plan); err != nil {
		writeError(w, http.StatusInternalServerError, "plan guncellenemedi")
		return
	}

	writeJSON(w, http.StatusOK, plan)
}

type changePINRequest struct {
	CurrentPIN string `json:"current_pin"`
	NewPIN     string `json:"new_pin"`
}

func (h *Handler) ChangePIN(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "yetkisiz erisim")
		return
	}

	var req changePINRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "gecersiz istek")
		return
	}

	if req.CurrentPIN == "" || req.NewPIN == "" {
		writeError(w, http.StatusBadRequest, "mevcut ve yeni pin gerekli")
		return
	}

	if err := h.repo.UpdatePIN(r.Context(), user.ID, req.CurrentPIN, req.NewPIN); err != nil {
		switch err {
		case ErrInvalidPIN:
			writeError(w, http.StatusBadRequest, "yeni pin en az 4 hane olmali")
		case ErrWrongPIN:
			writeError(w, http.StatusUnauthorized, "mevcut pin hatali")
		default:
			writeError(w, http.StatusInternalServerError, "pin guncellenemedi")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
