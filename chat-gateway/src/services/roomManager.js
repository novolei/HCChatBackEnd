// services/roomManager.js
// 房间（频道）管理服务

const rooms = new Map();

/**
 * 添加用户到房间
 */
function addUser(channel, ws) {
  if (!rooms.has(channel)) {
    rooms.set(channel, new Set());
  }
  rooms.get(channel).add(ws);
}

/**
 * 从房间移除用户
 */
function removeUser(channel, ws) {
  const room = rooms.get(channel);
  if (!room) return;
  
  room.delete(ws);
  if (room.size === 0) {
    rooms.delete(channel);
  }
}

/**
 * 获取房间的用户列表（昵称）
 */
function getUsers(channel) {
  const room = rooms.get(channel);
  if (!room) return [];
  
  return Array.from(room).map(ws => ws.nick || 'guest');
}

/**
 * 获取房间的用户连接（WebSocket 对象）
 */
function getRoomUsers(channel) {
  return rooms.get(channel) || new Set();
}

/**
 * 清理空房间
 */
function cleanup() {
  for (const [channel, users] of rooms.entries()) {
    if (users.size === 0) {
      rooms.delete(channel);
    }
  }
}

module.exports = {
  addUser,
  removeUser,
  getUsers,
  getRoomUsers,
  cleanup,
};

