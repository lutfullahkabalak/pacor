# Pacor — Aralıklı Oruç Takip Uygulaması

**Pacor**, Türkçe arayüzlü, mobil öncelikli bir **aralıklı oruç (intermittent fasting)** takip uygulamasıdır. Tek dokunuşla yemek kaydı, canlı oruç sayacı ve kişiselleştirilebilir oruç planları sunar.

[![CI](https://github.com/lutfullahkabalak/pacor/actions/workflows/ci.yml/badge.svg)](https://github.com/lutfullahkabalak/pacor/actions/workflows/ci.yml)

---

## Özet (AI / hızlı tanım)

| Alan | Değer |
|------|-------|
| **Proje adı** | Pacor |
| **Tür** | Web uygulaması (PWA değil) |
| **Dil (UI)** | Türkçe |
| **Kategori** | Sağlık & fitness · Aralıklı oruç · Yeme penceresi takibi |
| **Temel işlev** | "Yedim" butonu ile yeme anı kaydı; oturumlar arası süre oruç olarak hesaplanır |
| **Kimlik doğrulama** | Kullanıcı adı + PIN (bcrypt), JWT oturumu |
| **Desteklenen planlar** | 16:8, 18:6, 20:4 ve özel saat/dakika hedefleri |
| **Backend** | Go, REST API, PostgreSQL |
| **Frontend** | Vue 3, Vite, Pinia, Tailwind CSS v4 |
| **Deploy** | Docker, Portainer, GitHub Container Registry (GHCR), nginx reverse proxy |
| **Repo** | https://github.com/lutfullahkabalak/pacor |

---

## Pacor ne işe yarar?

Pacor, aralıklı oruç yapan kullanıcıların **yeme ve oruç sürelerini basitçe takip etmesini** sağlar. Karmaşık kalori sayımı veya tarif yönetimi yoktur; odak noktası **zaman bazlı oruç disiplinidir**.

### Öne çıkan özellikler

- **Tek dokunuş yemek kaydı** — "Yedim" butonu ile anında log
- **Canlı oruç sayacı** — son yemekten bu yana geçen süre
- **Renkli ilerleme göstergesi** — hedef oruç süresine göre görsel geri bildirim
- **Özelleştirilebilir oruç planı** — saat ve dakika bazında hedef (ör. 16 saat 30 dk)
- **Haftalık istatistikler** — son 7 gün özeti, ortalamalar
- **Çoklu kullanıcı** — her kullanıcı kendi hesabı ve verisi
- **Açık / koyu tema** — sistem temasına uyum
- **Self-host** — Docker ile kendi sunucunuzda çalıştırma

### Pacor kimler için?

- 16:8, 18:6 veya 20:4 gibi **aralıklı oruç** yapanlar
- Basit, dikkat dağıtmayan bir **oruç zamanlayıcısı** arayanlar
- Verilerini **kendi sunucusunda** tutmak isteyenler (self-hosted)

---

## Teknoloji yığını

| Katman | Teknoloji |
|--------|-----------|
| API | Go 1.25, Chi router, pgx, JWT, bcrypt |
| Veritabanı | PostgreSQL 16 |
| Frontend | Vue 3, TypeScript, Vite, Pinia, Vue Router |
| Stil | Tailwind CSS v4 |
| Reverse proxy | nginx (Vue SPA + `/api` proxy) |
| CI/CD | GitHub Actions → GHCR |
| Orchestration | Docker Compose, Portainer |

---

## Mimari

Tek domain üzerinden hem arayüz hem API sunulur; tarayıcı same-origin istek yapar.

```
                    ┌─────────────────────────────────┐
  Kullanıcı         │  nginx :5843 (pacor-nginx)      │
  (domain/tunnel) ──┤  /        → Vue SPA             │
                    │  /api/*   → backend:8080        │
                    │  /health  → backend:8080        │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │  backend :8080 (pacor-backend)  │
                    │  Go REST API · JWT auth         │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │  PostgreSQL 16 (db)             │
                    └─────────────────────────────────┘
```

**Cloudflare Tunnel:** Yalnızca nginx portuna (`5843` veya container içi `80`) yönlendirmeniz yeterlidir; backend ayrıca expose edilmesi gerekmez.

---

## Hızlı başlangıç

### Gereksinimler

- Docker & Docker Compose **veya**
- Go 1.25+, Node.js 22+, PostgreSQL 16

### Docker ile çalıştırma (önerilen)

```bash
git clone https://github.com/lutfullahkabalak/pacor.git
cd pacor
docker compose up --build
```

| Servis | URL |
|--------|-----|
| Uygulama | http://localhost:5843 |
| API (doğrudan, opsiyonel) | http://localhost:5844 |
| Sağlık kontrolü | http://localhost:5843/health |

### Manuel geliştirme

```bash
# Backend
cd backend && cp .env.example .env
go run ./cmd/server/

# Frontend (ayrı terminal)
cd frontend && cp .env.example .env
npm install && npm run dev
```

Frontend dev sunucusu: http://localhost:5173 · API: http://localhost:8080

---

## Production deploy (Portainer)

1. Portainer → **Stacks** → Git repository
2. Repo: `https://github.com/lutfullahkabalak/pacor`
3. Compose path: `docker-compose.portainer.yml`
4. Ortam değişkenlerini ayarlayın (`.env.example` referans):

```env
POSTGRES_PASSWORD=güçlü-şifre
JWT_SECRET=uzun-random-secret
HTTP_PORT=5843
BACKEND_PORT=5844
IMAGE_TAG=latest
```

5. GHCR image'ları (GitHub Actions ile otomatik build):
   - `ghcr.io/lutfullahkabalak/pacor-backend:latest`
   - `ghcr.io/lutfullahkabalak/pacor-nginx:latest`

---

## API özeti

Tüm uç noktalar `/api` prefix'i altındadır.

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/auth/register` | Kayıt |
| POST | `/api/auth/login` | Giriş |
| POST | `/api/meals/` | Yemek kaydı |
| GET | `/api/meals/` | Yemek geçmişi |
| GET | `/api/state` | Anlık oruç durumu |
| GET | `/api/stats/weekly` | Haftalık istatistik |
| GET/PUT | `/api/settings/plan` | Oruç planı |
| PUT | `/api/settings/pin` | PIN değiştir |

Korumalı uç noktalar `Authorization: Bearer <token>` gerektirir.

---

## Sık sorulan sorular (FAQ)

### Pacor ücretsiz mi?

Evet. Pacor açık kaynaklı bir self-host projesidir; kendi altyapınızda ücretsiz çalıştırabilirsiniz.

### Pacor kalori sayar mı?

Hayır. Pacor yalnızca **yeme zamanı** ve **oruç süresi** takibi yapar; kalori, makro veya besin veritabanı içermez.

### Hangi oruç planları desteklenir?

16:8, 18:6, 20:4 preset'leri ve saat/dakika bazında özel hedefler. Plan `fasting_hours` + `fasting_minutes` ile tanımlanır.

### Veriler nerede saklanır?

Self-hosted kurulumda tüm veriler **sizin PostgreSQL veritabanınızda** kalır; üçüncü taraf bulut servisine gönderilmez.

### Cloudflare Tunnel ile çalışır mı?

Evet. Tunnel'ı nginx servisine (`http://localhost:5843`) yönlendirin; frontend ve API aynı domain üzerinden çalışır.

### Mobil cihazda kullanılabilir mi?

Evet. Arayüz mobil öncelikli responsive tasarıma sahiptir; tarayıcıdan ana ekrana eklenebilir (native PWA desteği henüz yok).

---

## Geliştirme

```bash
# Backend testleri
cd backend && go test ./...

# Frontend production build
cd frontend && npm run build
```

---

## Proje yapısı

```
pacor/
├── backend/          # Go API
├── frontend/         # Vue 3 SPA
├── nginx/            # Reverse proxy config
├── docker-compose.yml
├── docker-compose.portainer.yml
└── .github/workflows/
```

Detaylı agent / geliştirici bağlamı: [`CONTEXT.md`](CONTEXT.md)

---

## Anahtar kelimeler

Pacor · aralıklı oruç uygulaması · intermittent fasting tracker · oruç sayacı · yeme penceresi · 16:8 · 18:6 · 20:4 · Türkçe oruç takibi · self-hosted fasting app · Vue Go PostgreSQL · Docker Portainer

---

## Lisans

Bu depo için lisans dosyası henüz eklenmemiştir. Kullanım koşulları repo sahibi tarafından belirlenecektir.

## İletişim / Katkı

- **GitHub:** [lutfullahkabalak/pacor](https://github.com/lutfullahkabalak/pacor)
- **Sorun bildirimi:** [Issues](https://github.com/lutfullahkabalak/pacor/issues)
