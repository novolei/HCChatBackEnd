/**
 * 处理正在输入事件
 */

const roomManager = require('../services/roomManager');

/**
 * 处理用户正在输入事件
 * @param {WebSocket} ws - 发送者的 WebSocket 连接
 * @param {Object} msg - 消息对象 { cmd: 'typing', channel: '...', nick: '...' }
 */
function handleTyping(ws, msg) {
  const channel = msg.channel || ws.channel;
  const nickname = msg.nick || ws.nick || 'guest';

  if (!channel) {
    console.warn('⚠️ typing 事件缺少 channel 信息');
    return;
  }

  console.log(`📝 ${nickname} 正在 ${channel} 输入`);

  // 广播给同一频道的其他用户（不包括发送者自己）
  const broadcast = {
    cmd: 'typing',
    channel: channel,
    nick: nickname
  };

  // 获取房间内的所有用户
  const roomUsers = roomManager.getRoomUsers(channel);
  
  // 广播给除了发送者之外的所有用户
  for (const user of roomUsers) {
    if (user.ws !== ws && user.ws.readyState === 1) { // WebSocket.OPEN = 1
      user.ws.send(JSON.stringify(broadcast));
    }
  }
}

module.exports = { handleTyping };

