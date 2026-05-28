# Proje Bağlamı — Pacor (Aralıklı Oruç)

> **AGENT TALİMATI:** Bu dosyayı ilk oku. Görevi anlamak, mimariyi kavramak ve nerede ne değiştireceğine karar vermek için **yalnızca bu dosyayı kullan**. Başka dosyaları tarama, glob/grep/read yapma — ancak gerçekten kod yazacak veya hata ayıklayacaksan ve ihtiyacın olan bilgi burada yoksa ilgili tek dosyayı aç. Kullanıcı uygulamanın mevcut halinden memnun; gereksiz refactor veya kapsam genişletmesi yapma. Süreç kuralları için `INSTRUCTIONS.md`'ye uy.

---

## Ne bu?

**Pacor**, mobil öncelikli bir **aralıklı oruç (intermittent fasting) takip uygulamasıdır**. Kullanıcı **"Yedim"** butonuna basarak yeme anını loglar; sistem oturumlar arası süreyi oruç olarak hesaplar. Çoklu kullanıcı, basit **kullanıcı adı + PIN** ile giriş. Arayüz Türkçe.

**GitHub:** [lutfullahkabalak/pacor](https://github.com/lutfullahkabalak/pacor)

**Stack:** Go (Chi, pgx, JWT, bcrypt) + Vue 3 (Vite, Pinia, Vue Router, Tailwind v4) + PostgreSQL + nginx

---

## Çalıştırma

### Lokal geliştirme (Docker — tam stack)

```bash
cp .env.example .env   # opsiyonel; varsayılan portlar: nginx 5843, backend 5844, Postgres host 5433
docker compose up --build
```

**Not:** `POSTGRES_PORT` varsayılan `5433` (host). `5432` genelde yerel Postgres veya başka container tarafından dolu olur; backend container içinde yine `db:5432` kullanır.

| Servis | Adres |
|--------|-------|
| UI + API (nginx) | http://localhost:5843 |
| API doğrudan (dev) | http://localhost:5844 |
| Health | GET http://localhost:5843/health |

### Lokal geliştirme (manuel)

```bash
# Backend
cd backend && cp .env.example .env
DATABASE_URL=postgres://oruc:oruc@localhost:5432/oruc?sslmode=disable go run ./cmd/server/

# Frontend
cd frontend && cp .env.example .env
npm install && npm run dev
```

Vite dev: `VITE_API_URL` boş bırakılırsa `/api` otomatik `localhost:5844`'e proxy edilir (docker compose). **8080'de başka servis olabilir** — Pacor API docker'da `5844`, nginx'te `5843`.

| Servis | Adres |
|--------|-------|
| API (docker compose) | http://localhost:5844 |
| UI + API (docker nginx) | http://localhost:5843 |
| UI (Vite dev) | http://localhost:5173 |
| API (manuel go run) | http://localhost:8080 — `.env` içinde `VITE_API_URL=http://localhost:8080` |
| Health | GET /health |

**Test:** `cd backend && go test ./...` · **Build:** `cd frontend && npm run build`

---

## Deploy (Portainer + GHCR)

**Production compose:** `docker-compose.portainer.yml` — kaynak kod **build etmez**, GitHub Actions ile üretilen image'ları çeker.

| Image | GHCR |
|-------|------|
| Backend | `ghcr.io/lutfullahkabalak/pacor-backend:latest` |
| nginx (Vue SPA + reverse proxy) | `ghcr.io/lutfullahkabalak/pacor-nginx:latest` |

**Portainer:** Stack → Git repo → compose path: `docker-compose.portainer.yml`

**Varsayılan host portları:** nginx `5843`, backend `5844` (opsiyonel doğrudan API)

**Tek domain mimarisi:** Dışarıya yalnızca **nginx** açılır. nginx `/` → Vue static, `/api/` → `backend:8080` proxy. Cloudflare Tunnel için `http://localhost:5843` veya container içi `http://nginx:80` yeterli.

**CI/CD:**
- `.github/workflows/ci.yml` — test + build doğrulama
- `.github/workflows/publish.yml` — `main` push'ta GHCR'a image publish

**nginx config:** `nginx/default.conf` · **nginx image build:** `frontend/Dockerfile` (Node build → `nginx:alpine`)

---

## Dizin yapısı

```
pacor/
├── CONTEXT.md                    ← bu dosya (agent tek kaynak)
├── README.md                     ← insan + SEO / AI SEO dokümantasyonu
├── INSTRUCTIONS.md               ← agent süreç kuralları
├── docker-compose.yml            ← lokal dev (build)
├── docker-compose.portainer.yml  ← production (GHCR pull)
├── .env.example                  ← Portainer / compose env şablonu
├── nginx/default.conf            ← tek domain SPA + API proxy
├── .github/workflows/            ← ci.yml, publish.yml
├── backend/
│   ├── cmd/server/main.go
│   ├── internal/auth|config|database|users|meals/
│   ├── Dockerfile
│   └── .env.example
└── frontend/
    ├── Dockerfile                ← Vue build + nginx image
    ├── src/api/client.ts
    ├── src/stores/               ← auth, meals, settings, theme
    ├── src/views/                ← LoginView, HomeView
    ├── src/components/           ← MealButton, StatsModal, SettingsModal, ...
    └── .env.example
```

**Not:** Aktif migration'lar `backend/internal/database/migrations/`. `backend/migrations/` eski kopya, kullanılmıyor.

---

## Veritabanı

| Tablo | Alanlar |
|-------|---------|
| `users` | id, username (unique), pin_hash, created_at |
| `user_settings` | user_id PK, plan_type, eating_hours, fasting_hours, **fasting_minutes**, updated_at |
| `meal_logs` | id, user_id, logged_at, note |

Varsayılan plan: `16_8` → eating=8, fasting=16, fasting_minutes=0.

---

## API (tümü `/api` altında)

Production'da nginx üzerinden same-origin: `/api/...`. Dev'de frontend `VITE_API_URL=http://localhost:8080`.

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
| PUT | `/settings/plan` | Plan güncelle `{plan_type, eating_hours, fasting_hours, fasting_minutes}` |
| PUT | `/settings/pin` | PIN değiştir `{current_pin, new_pin}` |

---

## İş mantığı (meals/stats.go)

- **Oturum gruplama:** 30 dk içindeki yemekler aynı yeme oturumu (`SESSION_GAP_MINUTES` env).
- **Oruç:** Oturumlar arası boşluk = oruç süresi.
- **Tek dokunuş yeme süresi:** Oturumda tek kayıt varsa min 15 dk yeme sayılır.
- **Plan durumu (`plan_status`):** `green` / `yellow` / `red` / `gray`
- **Hedef süre:** `fasting_hours * 60 + fasting_minutes`
- Saf fonksiyonlar unit testli: `backend/internal/meals/stats_test.go`

---

## Frontend

### Rotalar
| Path | View | İçerik |
|------|------|--------|
| `/login` | LoginView | Kayıt/giriş |
| `/` | HomeView | Oruç sayacı, **Yedim** butonu, ayarlar/istatistik modalları |
| `/stats`, `/settings` | — | `home`'a redirect (modal kullanılıyor) |

### Pinia store'lar
- **auth** — token/username localStorage
- **meals** — state, logMeal, weekly, deleteMeal; StatsModal
- **settings** — plan fetch/save, PIN değiştir; SettingsModal
- **theme** — sistem açık/koyu tema

### Önemli bileşenler
`MealButton` · `StatsModal` · `SettingsModal` · `PlanPicker` · `StatsFab` · `PacManIcon`

**Arka plan:** `background-9509852_1280.jpg` → web: `frontend/public/background.jpg` (`--bg-image-opacity` ~%12–14, `.page-bg`); iOS: `Assets.xcassets/Background` + `AppPageBackground` (koyu %14, açık %12, gradyan üstü). `FoodEmojiBackground` şimdilik kapalı.

**iOS arka plan layout (önemli):** `AppPageBackground` `RootView`'da `.background { }` ile uygulanır — ZStack kardeşi DEĞİL. Kardeş yapılırsa `.ignoresSafeArea()` ZStack sınırını büyütüp içeriğin güvenli alanını bozar → header (logo/ayarlar) dynamic island altına, FAB ekran dışına kayar. UI'nin geri kalanı orijinal Liquid Glass (`glassPanel` / `glassCircle` / `glassInput`) ile çalışır; bunlara dokunulmadı.

### API client
- Dev: `VITE_API_URL` veya `http://localhost:8080`
- Prod: same-origin (`import.meta.env.PROD ? '' : ...`) — nginx `/api/` proxy ile uyumlu

### CORS
Dev Vite için `localhost:5173` / `127.0.0.1:5173`. Production nginx same-origin olduğu için tarayıcı CORS sorunu yok.

---

## Bilinçli olarak yok (plan dışı)

Push bildirimi, PWA/offline, kalori/fotoğraf, admin paneli, SQLite, login rate limit, ayrı `/stats` ve `/settings` sayfaları.

---

## Bilinen eksikler (dokunma unless asked)

1. Login rate limit yok
2. Mobil LAN erişimi için CORS kısıtlı (dev)
3. `tasks/todo.md` ve `tasks/lessons.md` henüz yok

---

## Agent süreci (kısa)

`INSTRUCTIONS.md` kurallarına uy. Görev takibi için `tasks/todo.md` + `tasks/lessons.md` kullanılmalı (henüz oluşturulmadı).

---

## Ne zaman başka dosya açılır?

| Durum | Açılacak dosya |
|-------|----------------|
| Route/handler ekle | `backend/cmd/server/main.go` |
| nginx / tek domain | `nginx/default.conf`, `frontend/Dockerfile` |
| Deploy / Portainer | `docker-compose.portainer.yml`, `.env.example` |
| CI / image publish | `.github/workflows/` |
| İstatistik mantığı | `backend/internal/meals/stats.go` |
| Auth değişikliği | `backend/internal/auth/`, `backend/internal/users/` |
| Yeni API çağrısı | `frontend/src/api/client.ts` + ilgili store |
| UI ekranı / modal | `frontend/src/views/*.vue`, `frontend/src/components/*.vue` |
| Migration | `backend/internal/database/migrations/` |

Bunun dışında tarama yapma.
