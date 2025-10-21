# hc-stack (FASTPANEL + high ports)

Domains:
- hc.go-lv.com          → chat & api
- livekit.hc.go-lv.com  → LiveKit signaling
- s3.hc.go-lv.com       → MinIO S3 API
- mc.s3.hc.go-lv.com    → MinIO Console

Steps:
1) Edit infra/livekit.yaml (replace CHANGE_ME_*).
2) cp infra/.env.example infra/.env  → 填好 MINIO_* / LIVEKIT_* / JWT_SIGNING_SECRET
3) cd infra && docker compose up -d
4) 在 FASTPANEL 给四个域名建站 + 粘贴 infra/fastpanel/nginx_snippets/*.conf
5) 防火墙：开放 80/443；14788/tcp,udp；51000–52000/udp

Health:
- curl -I http://127.0.0.1:10081/api/health
- curl -I http://127.0.0.1:10090/minio/health/ready
