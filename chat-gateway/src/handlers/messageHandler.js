// handlers/messageHandler.js
// 处理聊天消息

const { broadcast } = require('../services/broadcaster');

function handleMessage(ws, msg) {
  if (!ws.channel || typeof msg.text !== 'string') return;
  
  // 广播消息到频道（转发客户端的 id，支持客户端去重）
  broadcast(ws.channel, {
    type: 'message',
    channel: ws.channel,
    nick: ws.nick || 'guest',
    text: msg.text,
    id: msg.id  // 保留客户端的消息 ID
  });
}

module.exports = handleMessage;

