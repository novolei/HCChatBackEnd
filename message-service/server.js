'use strict';
const express = require('express');
const cors = require('cors');
const { URL } = require('url');
const Minio = require('minio');
const { AccessToken } = require('livekit-server-sdk');

const PORT = Number(process.env.PORT || 3000);
const MINIO_ENDPOINT = process.env.MINIO_ENDPOINT || 'https://s3.hc.go-lv.com';
const MINIO_ROOT_USER = process.env.MINIO_ROOT_USER || 'admin';
const MINIO_ROOT_PASSWORD = process.env.MINIO_ROOT_PASSWORD || 'password'; // ✅ 别写错
const MINIO_DEFAULT_BUCKET = process.env.MINIO_DEFAULT_BUCKET || 'hc-attachments';

const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY || '';
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET || '';
const LIVEKIT_WS_URL = process.env.LIVEKIT_WS_URL || 'wss://livekit.hc.go-lv.com';

const CORS_ALLOW = (process.env.CORS_ALLOW_ORIGINS || '*')
  .split(',').map(s => s.trim()).filter(Boolean);

const u = new URL(MINIO_ENDPOINT);
const minio = new Minio.Client({
  endPoint: u.hostname,
  port: u.port ? Number(u.port) : (u.protocol === 'https:' ? 443 : 80),
  useSSL: u.protocol === 'https:',
  accessKey: MINIO_ROOT_USER,
  secretKey: MINIO_ROOT_PASSWORD,
});

const app = express();
app.set('trust proxy', true);
app.use(express.json({ limit: '2mb' }));
app.use(cors({
  origin: (origin, cb) => (!origin || CORS_ALLOW.includes('*') || CORS_ALLOW.includes(origin)) ? cb(null, true) : cb(new Error('CORS'), false),
}));

app.get('/healthz', (_req, res) => res.json({ ok: true }));  // ✅ 健康路由

app.post('/api/attachments/presign', async (req, res) => {
  try {
    const { objectKey, contentType } = req.body || {};
    if (!objectKey) return res.status(400).json({ error: 'objectKey required' });
    const putUrl = await minio.presignedPutObject(
      MINIO_DEFAULT_BUCKET, objectKey, 600, { 'Content-Type': contentType || 'application/octet-stream' }
    );
    const getUrl = await minio.presignedGetObject(MINIO_DEFAULT_BUCKET, objectKey, 7 * 24 * 3600);
    res.json({ bucket: MINIO_DEFAULT_BUCKET, objectKey, putUrl, getUrl, expiresSeconds: 600 });
  } catch (e) { console.error('presign error:', e); res.status(500).json({ error: 'presign failed' }); }
});

app.post('/api/rtc/token', async (req, res) => {
  try {
    const { room, identity, metadata } = req.body || {};
    if (!room || !identity) return res.status(400).json({ error: 'room & identity required' });
    if (!LIVEKIT_API_KEY || !LIVEKIT_API_SECRET) return res.status(500).json({ error: 'livekit not configured' });
    const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, { identity: String(identity), ttl: 3600, metadata: metadata ? String(metadata) : undefined });
    at.addGrant({ roomJoin: true, room: String(room), canPublish: true, canSubscribe: true, canPublishData: true });
    const token = await at.toJwt();
    res.json({ livekitUrl: LIVEKIT_WS_URL, token });
  } catch (e) { console.error('rtc token error:', e); res.status(500).json({ error: 'token failed' }); }
});

app.use((err, _req, res, _next) => { console.error('unhandled error:', err); res.status(500).json({ error: 'internal' }); });

app.listen(PORT, '0.0.0.0', () => console.log(`message-service listening on :${PORT}`)); // ✅ 显式 0.0.0.0

