# Proje Bağlamı — Aralıklı Oruç

> **AGENT TALİMATI:** Bu dosyayı ilk oku. Görevi anlamak, mimariyi kavramak ve nerede ne değiştireceğine karar vermek için **yalnızca bu dosyayı kullan**. Başka dosyaları tarama, glob/grep/read yapma — ancak gerçekten kod yazacak veya hata ayıklayacaksan ve ihtiyacın olan bilgi burada yoksa ilgili tek dosyayı aç. Kullanıcı uygulamanın mevcut halinden memnun; gereksiz refactor veya kapsam genişletmesi yapma. Süreç kuralları için `INSTRUCTIONS.md`'ye uy.

---

## Ne bu?

Mobil öncelikli aralıklı oruç takip uygulaması. Kullanıcı **"Yedim"** butonuna basarak yeme anını loglar; sistem oturumlar arası süreyi oruç olarak hesaplar. Çoklu kullanıcı, basit **kullanıcı adı + PIN** ile giriş. Arayüz Türkçe.

**Stack:** Go (Chi, pgx, JWT, bcrypt) + Vue 3 (Vite, Pinia, Vue Router, Tailwind v4)

---

## Çalıştırma

```bash
# Docker (db + backend)
docker compose up --build

# Manuel backend
cd backend && cp .env.example .env
DATABASE_URL=postgres://oruc:oruc@localhost:5432/oruc?sslmode=disable go run ./cmd/server/

# Manuel frontend
cd frontend && cp .env.example .env
npm install && npm run dev
```

| Servis | Adres |
|--------|-------|
| API | http://localhost:8080 |
| UI | http://localhost:5173 |
| Health | GET /health |

**Test:** `cd backend && go test ./...` · **Build:** `cd frontend && npm run build`

---

## Dizin yapısı

```
aralıklıoruç/
├── CONTEXT.md          ← bu dosya (tek kaynak)
├── INSTRUCTIONS.md     ← agent süreç kuralları
├── docker-compose.yml  ← postgres + backend (frontend yok)
├── backend/
│   ├── cmd/server/main.go       ← router, CORS, route tanımları
│   ├── internal/
│   │   ├── auth/                ← JWT üret/parse, Bearer middleware
│   │   ├── config/config.go     ← env okuma
│   │   ├── database/            ← pgx pool + embed migration
│   │   ├── users/               ← kayıt/giriş, plan CRUD
│   │   └── meals/               ← yemek log, istatistik, handler
│   ├── Dockerfile
│   └── .env.example
└── frontend/
    ├── src/
    │   ├── api/client.ts        ← tüm API çağrıları
    │   ├── stores/              ← auth, meals, settings (Pinia)
    │   ├── views/               ← Login, Home, Stats, Settings
    │   ├── components/          ← FastingTimer, MealButton, BottomNav, ...
    │   ├── router/index.ts
    │   └── types/index.ts
    └── .env.example
```

**Not:** Aktif migration `backend/internal/database/migrations/001_init.sql`. `backend/migrations/` eski kopya, kullanılmıyor.

---

## Veritabanı

| Tablo | Alanlar |
|-------|---------|
| `users` | id, username (unique), pin_hash, created_at |
| `user_settings` | user_id PK, plan_type, eating_hours, fasting_hours, updated_at |
| `meal_logs` | id, user_id, logged_at, note |

Varsayılan plan: `16_8` → eating=8, fasting=16.

---

## API (tümü `/api` altında)

### Auth (korumasız)
| Method | Path | Body | Dönüş |
|--------|------|------|-------|
| POST | `/auth/register` | `{username, pin}` | `{token, username, user_id}` |
| POST | `/auth/login` | `{username, pin}` | `{token, username, user_id}` |

PIN min 4 hane, bcrypt hash. JWT varsayılan 7 gün (`JWT_EXPIRY_HOURS`).

### Korumalı (Header: `Authorization: Bearer <token>`)
| Method | Path | Açıklama |
|--------|------|----------|
| POST | `/meals/` | Yemek kaydı (body opsiyonel: `logged_at`, `note`) |
| GET | `/meals/?from=&to=` | Geçmiş (YYYY-MM-DD, varsayılan son 30 gün) |
| DELETE | `/meals/{id}` | Kayıt sil |
| GET | `/stats/daily?date=` | Günlük istatistik |
| GET | `/stats/weekly?end=` | 7 günlük özet |
| GET | `/state` | Anlık durum: son yemekten beri süre + bugün özeti |
| GET | `/settings/plan` | Plan oku |
| PUT | `/settings/plan` | Plan güncelle `{plan_type, eating_hours, fasting_hours}` |

---

## İş mantığı (meals/stats.go)

- **Oturum gruplama:** 30 dk içindeki yemekler aynı yeme oturumu (`SESSION_GAP_MINUTES` env).
- **Oruç:** Oturumlar arası boşluk = oruç süresi.
- **Tek dokunuş yeme süresi:** Oturumda tek kayıt varsa min 15 dk yeme sayılır.
- **Plan durumu (`plan_status`):** `green` / `yellow` / `red` / `gray`
  - Yeme süresi ≤ hedef eating_hours
  - En uzun oruç (veya bugünkü current fast) ≥ hedef fasting_hours
- Saf fonksiyonlar unit testli: `backend/internal/meals/stats_test.go`

---

## Frontend

### Rotalar
| Path | View | İçerik |
|------|------|--------|
| `/login` | LoginView | Kayıt/giriş, PIN input |
| `/` | HomeView | Oruç sayacı, **Yedim** butonu, bugün özeti |
| `/stats` | StatsView | Son 7 gün bar listesi, ortalamalar |
| `/settings` | SettingsView | Plan seçimi, son kayıtlar sil, çıkış |

### Pinia store'lar
- **auth** — token/username localStorage'da, login/register/logout
- **meals** — state, logMeal, weekly, recent meals, deleteMeal
- **settings** — plan fetch/save, presetler (16_8, 18_6, 20_4)

### Bileşenler
`FastingTimer` (canlı sayaç) · `MealButton` · `TodaySummary` · `PlanPicker` · `BottomNav`

### Env
- Backend: `DATABASE_URL`, `JWT_SECRET`, `PORT`, `SESSION_GAP_MINUTES`
- Frontend: `VITE_API_URL` (default `http://localhost:8080`)

### CORS
Sadece `localhost:5173` ve `127.0.0.1:5173`. Telefondan LAN IP ile erişimde CORS güncellemesi gerekir (`main.go`).

---

## Bilinçli olarak yok (plan dışı / sonraki adım)

Push bildirimi, PWA/offline, grafik kütüphanesi, kalori/fotoğraf, admin paneli, SQLite, login rate limit, istatistikte günlük/haftalık tab ayrımı, gerçek numpad UI, CI pipeline, kök README.

---

## Bilinen eksikler (kullanıcı mevcut hali onayladı — dokunma unless asked)

1. Login rate limit yok
2. `/stats/daily` API var, UI'da ayrı günlük tab yok (bugün ana ekranda)
3. Mobil LAN erişimi için CORS kısıtlı
4. `tasks/todo.md` ve `tasks/lessons.md` henüz yok (`INSTRUCTIONS.md` gereksinimi)

---

## Agent süreci (kısa)

`INSTRUCTIONS.md` kurallarına uy: plan önce, doğrulama kanıtla, sadelik, otomatik hata düzeltme. Görev takibi için `tasks/todo.md` + `tasks/lessons.md` kullanılmalı (henüz oluşturulmadı).

---

## Ne zaman başka dosya açılır?

| Durum | Açılacak dosya |
|-------|----------------|
| Route/handler ekle | `backend/cmd/server/main.go` |
| İstatistik mantığı | `backend/internal/meals/stats.go` |
| Auth değişikliği | `backend/internal/auth/`, `backend/internal/users/` |
| Yeni API çağrısı | `frontend/src/api/client.ts` + ilgili store |
| UI ekranı | `frontend/src/views/*.vue` |
| Migration | `backend/internal/database/migrations/` |

Bunun dışında tarama yapma.
