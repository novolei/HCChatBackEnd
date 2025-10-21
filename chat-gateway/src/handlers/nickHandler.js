// handlers/nickHandler.js
// 处理昵称变更

const { broadcast, sendToUser } = require('../services/broadcaster');

function handleNick(ws, msg) {
  if (!msg.nick) return;
  
  const oldNick = ws.nick || 'guest';
  const newNick = msg.nick;
  ws.nick = newNick;
  
  // 如果用户已加入频道，广播昵称变更通知
  if (ws.channel && oldNick !== newNick) {
    broadcast(ws.channel, {
      type: 'nick_change',
      oldNick: oldNick,
      newNick: newNick,
      channel: ws.channel
    });
  }
  
  // 发送确认消息给当前用户
  sendToUser(ws, {
    type: 'info',
    text: `昵称已更改为 ${newNick}`
  });
}

module.exports = handleNick;

