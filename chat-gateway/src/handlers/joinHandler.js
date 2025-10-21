// handlers/joinHandler.js
// 处理用户加入频道

const roomManager = require('../services/roomManager');
const { broadcast, sendToUser } = require('../services/broadcaster');

function handleJoin(ws, msg) {
  const channel = msg.room || msg.channel;
  if (!channel) return;
  
  ws.channel = channel;
  ws.nick = ws.nick || msg.nick || 'guest';
  
  // 添加到房间
  roomManager.addUser(ws.channel, ws);
  
  // 广播给频道内其他用户（不包括自己）
  broadcast(ws.channel, {
    type: 'user_joined',
    nick: ws.nick,
    channel: ws.channel
  }, ws);
  
  // 发送确认消息给当前用户
  sendToUser(ws, {
    type: 'info',
    text: `joined #${ws.channel}`
  });
}

module.exports = handleJoin;

