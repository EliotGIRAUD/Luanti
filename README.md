## Luanti stack avec monitoring (TP)

Ce projet met en place une stack Docker complète autour d’un serveur **Luanti** :

- serveur de jeu Luanti compilé depuis les sources avec le support **Prometheus** activé,
- monitoring via **Prometheus** + **Grafana** (provisioning automatique),
- landing page **Nginx** servant de point d’entrée.

### 1. Arborescence

- `Dockerfile` : build multi‑stage Luanti (compilation + image runtime).
- `docker-compose.yml` : services `luanti`, `prometheus`, `grafana`, `web`.
- `minetest/minetest.conf` : configuration du serveur Luanti.
- `prometheus/prometheus.yml` : configuration du scrape Prometheus.
- `grafana/provisioning/datasources/datasource.yml` : datasource Prometheus auto-provisionnée.
- `grafana/provisioning/dashboards/dashboards.yml` : provisioning automatique des dashboards.
- `grafana/dashboards/luanti-minimal.json` : dashboard Grafana minimal pour Luanti.
- `web/index.html` : landing page générée avec l’aide d’une IA.
- `web/hero.svg` : illustration “IA-like” utilisée sur la landing page.

### 2. Build & run

Depuis le répertoire `luanti-stack/` :

```bash
# Build et lancement en arrière-plan
docker compose up -d --build

# Vérifier l’état des services
docker compose ps
