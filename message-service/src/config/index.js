// config/index.js
// 配置管理

module.exports = {
  PORT: Number(process.env.PORT || 3000),
  
  // MinIO 配置
  MINIO: {
    ENDPOINT: process.env.MINIO_ENDPOINT || 'https://s3.hc.go-lv.com',
    ROOT_USER: process.env.MINIO_ROOT_USER || 'admin',
    ROOT_PASSWORD: process.env.MINIO_ROOT_PASSWORD || 'password',
    DEFAULT_BUCKET: process.env.MINIO_DEFAULT_BUCKET || 'hc-attachments',
  },
  
  // LiveKit 配置
  LIVEKIT: {
    API_KEY: process.env.LIVEKIT_API_KEY || '',
    API_SECRET: process.env.LIVEKIT_API_SECRET || '',
    WS_URL: process.env.LIVEKIT_WS_URL || 'wss://livekit.hc.go-lv.com',
  },
  
  // CORS 配置
  CORS_ALLOW_ORIGINS: (process.env.CORS_ALLOW_ORIGINS || '*')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean),
};

