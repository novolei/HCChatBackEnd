// handlers/index.js
// 消息路由和分发

const joinHandler = require('./joinHandler');
const nickHandler = require('./nickHandler');
const whoHandler = require('./whoHandler');
const messageHandler = require('./messageHandler');
const roomManager = require('../services/roomManager');
const { broadcast } = require('../services/broadcaster');

/**
 * 处理接收到的消息
 */
function handleMessage(ws, data) {
  let msg = {};
  try {
    msg = JSON.parse(data.toString());
  } catch {
    return;
  }
  
  // 兼容 cmd 和 type 两种字段名
  const msgType = msg.type || msg.cmd;
  
  // 根据消息类型分发到不同的处理器
  switch (msgType) {
    case 'nick':
      nickHandler(ws, msg);
      break;
      
    case 'join':
      joinHandler(ws, msg);
      break;
      
    case 'who':
      whoHandler(ws, msg);
      break;
      
    case 'message':
    case 'chat':
      messageHandler(ws, msg);
      break;
      
    default:
      // 未知消息类型，忽略
      break;
  }
}

/**
 * 处理 WebSocket 连接建立
 */
function handleConnection(ws) {
  console.log('新用户连接');
  ws.nick = 'guest';
}

/**
 * 处理 WebSocket 连接关闭
 */
function handleClose(ws) {
  console.log(`用户断开: ${ws.nick || 'guest'}`);
  
  if (ws.channel && roomManager.getRoomUsers(ws.channel)) {
    // 广播用户离开通知（在删除之前）
    broadcast(ws.channel, {
      type: 'user_left',
      nick: ws.nick || 'guest',
      channel: ws.channel
    }, ws);
    
    // 从房间移除用户
    roomManager.removeUser(ws.channel, ws);
  }
}

module.exports = {
  handleMessage,
  handleConnection,
  handleClose,
};

