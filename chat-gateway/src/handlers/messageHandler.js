// handlers/messageHandler.js
// 处理聊天消息

const { broadcast } = require('../services/broadcaster');
const roomManager = require('../services/roomManager');

function handleMessage(ws, msg) {
  if (!ws.channel || typeof msg.text !== 'string') return;
  
  const messageId = msg.id || generateId();
  
  // ✨ P0: 立即发送 ACK 给发送者（确认服务器已收到）
  if (ws.readyState === 1) {
    try {
      ws.send(JSON.stringify({
        type: 'message_ack',
        messageId: messageId,
        status: 'received',
        timestamp: Date.now()
      }));
      console.log(`✅ ACK sent for message ${messageId}`);
    } catch (e) {
      console.error(`❌ Failed to send ACK: ${e.message}`);
    }
  }
  
  // 广播消息到频道（转发客户端的 id，支持客户端去重）
  const broadcastMsg = {
    type: 'message',
    channel: ws.channel,
    nick: ws.nick || 'guest',
    text: msg.text,
    id: messageId,  // 保留客户端的消息 ID
    attachment: msg.attachment  // 支持附件
  };
  
  // ✨ P1: 转发回复信息（如果有）
  if (msg.replyTo) {
    broadcastMsg.replyTo = msg.replyTo;
    console.log(`💬 转发回复消息: ${ws.nick} -> ${msg.replyTo.sender}`);
  }
  
  broadcast(ws.channel, broadcastMsg);
  
  // 发送停止输入通知（用户已发送消息）
  const typingStoppedMsg = {
    type: 'typing_stopped',
    channel: ws.channel,
    nick: ws.nick || 'guest'
  };
  broadcast(ws.channel, typingStoppedMsg);
  
  // ✨ P0: 发送 delivered 确认（已送达其他用户）
  const channelUsers = roomManager.getRoomUsers(ws.channel);
  const deliveredTo = [];
  
  for (const user of channelUsers) {
    if (user !== ws && user.readyState === 1) {
      deliveredTo.push(user.nick || 'guest');
    }
  }
  
  // 如果有其他在线用户收到了消息，发送 delivered 确认
  if (deliveredTo.length > 0 && ws.readyState === 1) {
    try {
      ws.send(JSON.stringify({
        type: 'message_delivered',
        messageId: messageId,
        deliveredTo: deliveredTo,
        timestamp: Date.now()
      }));
      console.log(`📫 Delivered confirmation sent for ${messageId} to ${deliveredTo.length} users`);
    } catch (e) {
      console.error(`❌ Failed to send delivered confirmation: ${e.message}`);
    }
  }
}

// 简单的 ID 生成器（如果客户端没有提供）
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

module.exports = handleMessage;

