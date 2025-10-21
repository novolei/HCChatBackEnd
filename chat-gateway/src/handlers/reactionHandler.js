// handlers/reactionHandler.js
// 处理表情反应添加和移除

const { broadcast } = require('../services/broadcaster');

/**
 * 处理添加表情反应
 * @param {WebSocket} ws - 发送者的 WebSocket 连接
 * @param {Object} msg - 消息对象 { type: 'add_reaction', messageId, channel, emoji, reactionId?, timestamp? }
 */
function handleAddReaction(ws, msg) {
  const { messageId, channel, emoji, reactionId, timestamp } = msg;
  
  // 验证必要字段
  if (!messageId || !channel || !emoji) {
    console.warn(`⚠️ 添加反应数据不完整 from ${ws.nick || 'unknown'}`);
    return;
  }
  
  console.log(`👍 添加反应: ${ws.nick} -> ${emoji} (消息: ${messageId})`);
  
  // 广播反应添加到频道所有用户
  broadcast(channel, {
    type: 'reaction_added',
    messageId: messageId,
    channel: channel,
    emoji: emoji,
    userId: ws.nick || 'guest',
    reactionId: reactionId || generateId(),
    timestamp: timestamp || Date.now()
  });
  
  console.log(`📡 反应已广播到 #${channel}: ${emoji} by ${ws.nick}`);
}

/**
 * 处理移除表情反应
 * @param {WebSocket} ws - 发送者的 WebSocket 连接
 * @param {Object} msg - 消息对象 { type: 'remove_reaction', messageId, channel, emoji }
 */
function handleRemoveReaction(ws, msg) {
  const { messageId, channel, emoji } = msg;
  
  // 验证必要字段
  if (!messageId || !channel || !emoji) {
    console.warn(`⚠️ 移除反应数据不完整 from ${ws.nick || 'unknown'}`);
    return;
  }
  
  console.log(`👎 移除反应: ${ws.nick} <- ${emoji} (消息: ${messageId})`);
  
  // 广播反应移除到频道所有用户
  broadcast(channel, {
    type: 'reaction_removed',
    messageId: messageId,
    channel: channel,
    emoji: emoji,
    userId: ws.nick || 'guest',
    timestamp: Date.now()
  });
  
  console.log(`📡 反应移除已广播到 #${channel}: ${emoji} by ${ws.nick}`);
}

// 简单的 ID 生成器
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

module.exports = {
  handleAddReaction,
  handleRemoveReaction
};

