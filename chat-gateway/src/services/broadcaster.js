// services/broadcaster.js
// 消息广播服务

const roomManager = require('./roomManager');

/**
 * 向房间广播消息
 * @param {string} channel - 频道名
 * @param {object} packet - 消息包
 * @param {WebSocket} excludeWs - 排除的 WebSocket（通常是发送者）
 */
function broadcast(channel, packet, excludeWs = null) {
  const users = roomManager.getRoomUsers(channel);
  const text = JSON.stringify(packet);
  
  for (const ws of users) {
    // 排除指定的 WebSocket 连接
    if (ws === excludeWs) continue;
    
    if (ws.readyState === 1) {  // 1 = WebSocket.OPEN
      try {
        ws.send(text);
      } catch (err) {
        console.error('broadcast send error:', err.message);
      }
    }
  }
}

/**
 * 向特定用户发送消息
 * @param {WebSocket} ws - 目标 WebSocket
 * @param {object} packet - 消息包
 */
function sendToUser(ws, packet) {
  if (ws.readyState === 1) {
    try {
      ws.send(JSON.stringify(packet));
    } catch (err) {
      console.error('send to user error:', err.message);
    }
  }
}

module.exports = {
  broadcast,
  sendToUser,
};

