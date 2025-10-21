// handlers/whoHandler.js
// 处理在线用户列表查询

const roomManager = require('../services/roomManager');
const { sendToUser } = require('../services/broadcaster');

function handleWho(ws, msg) {
  if (!ws.channel) return;
  
  const users = roomManager.getUsers(ws.channel);
  
  sendToUser(ws, {
    type: 'presence',
    room: ws.channel,
    users,
    count: users.length
  });
}

module.exports = handleWho;

