package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/auth"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/config"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/database"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/meals"
	"github.com/lutfullahkabalak/aralikli-oruc/backend/internal/users"
)

func main() {
	cfg := config.Load()

	ctx := context.Background()
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()

	userRepo := users.NewRepository(pool)
	mealRepo := meals.NewRepository(pool)

	tokenGen := func(userID int, username string) (string, error) {
		return auth.GenerateToken(userID, username, cfg.JWTSecret, cfg.JWTExpiry)
	}

	userHandler := users.NewHandler(userRepo, tokenGen)
	mealHandler := meals.NewHandler(mealRepo, cfg.SessionGapMins)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Timeout(60 * time.Second))

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://127.0.0.1:5173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	r.Route("/api", func(api chi.Router) {
		api.Route("/auth", func(authRouter chi.Router) {
			authRouter.Post("/register", userHandler.Register)
			authRouter.Post("/login", userHandler.Login)
		})

		api.Group(func(protected chi.Router) {
			protected.Use(auth.Middleware(cfg.JWTSecret))

			protected.Route("/meals", func(mealsRouter chi.Router) {
				mealsRouter.Post("/", mealHandler.Create)
				mealsRouter.Get("/", mealHandler.List)
				mealsRouter.Delete("/{id}", mealHandler.Delete)
			})

			protected.Get("/stats/daily", mealHandler.DailyStats)
			protected.Get("/stats/weekly", mealHandler.WeeklyStats)
			protected.Get("/state", mealHandler.CurrentState)

			protected.Route("/settings", func(settings chi.Router) {
				settings.Get("/plan", userHandler.GetPlan)
				settings.Put("/plan", userHandler.UpdatePlan)
				settings.Put("/pin", userHandler.ChangePIN)
			})
		})
	})

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("shutdown: %v", err)
	}
}
