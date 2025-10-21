// server.js
// WebSocket 聊天网关入口文件
// 重构版本：简洁、分层、易维护

const WebSocket = require('ws');
const config = require('./config');
const { handleMessage, handleConnection, handleClose } = require('./handlers');

// 创建 WebSocket 服务器
const wss = new WebSocket.Server({ port: config.PORT });

console.log(`✅ chat-gateway listening on :${config.PORT}`);

// 处理新连接
wss.on('connection', (ws) => {
  handleConnection(ws);
  
  // 处理消息
  ws.on('message', (data) => {
    handleMessage(ws, data);
  });
  
  // 处理断开
  ws.on('close', () => {
    handleClose(ws);
  });
  
  // 处理错误
  ws.on('error', (err) => {
    console.error('WebSocket error:', err.message);
  });
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到 SIGTERM 信号，关闭服务器...');
  wss.close(() => {
    console.log('服务器已关闭');
    process.exit(0);
  });
});

