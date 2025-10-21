// server.js
// Message Service 入口文件
// 重构版本：简洁、分层、易维护

'use strict';
const express = require('express');
const cors = require('cors');
const config = require('./config');
const errorHandler = require('./middleware/errorHandler');

// 路由
const attachmentsRouter = require('./routes/attachments');
const rtcRouter = require('./routes/rtc');

// 创建 Express 应用
const app = express();

// 中间件
app.set('trust proxy', true);
app.use(express.json({ limit: '2mb' }));

// CORS 配置
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || config.CORS_ALLOW_ORIGINS.includes('*') || config.CORS_ALLOW_ORIGINS.includes(origin)) {
      cb(null, true);
    } else {
      cb(new Error('CORS'), false);
    }
  },
}));

// 健康检查
app.get('/healthz', (_req, res) => {
  res.json({ ok: true });
});

// API 路由
app.use('/api/attachments', attachmentsRouter);
app.use('/api/rtc', rtcRouter);

// 错误处理
app.use(errorHandler);

// 启动服务器
app.listen(config.PORT, '0.0.0.0', () => {
  console.log(`✅ message-service listening on :${config.PORT}`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到 SIGTERM 信号，关闭服务器...');
  process.exit(0);
});

