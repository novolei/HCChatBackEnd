// handlers/statusUpdateHandler.js
// 处理用户在线状态更新

const { broadcast } = require('../services/broadcaster');

/**
 * 处理用户状态更新
 * @param {WebSocket} ws - 发送者的 WebSocket 连接
 * @param {Object} msg - 消息对象 { type: 'status_update', status: 'online|away|busy|offline', timestamp: 1234567890 }
 */
function handleStatusUpdate(ws, msg) {
  const { status, timestamp } = msg;
  
  // 验证状态值
  const validStatuses = ['online', 'away', 'busy', 'offline'];
  if (!validStatuses.includes(status)) {
    console.warn(`⚠️ 无效的状态值: ${status} from ${ws.nick || 'unknown'}`);
    return;
  }
  
  // 更新 WebSocket 连接上的状态信息
  ws.userStatus = status;
  ws.lastStatusUpdate = timestamp || Date.now();
  
  console.log(`👤 状态更新: ${ws.nick || 'unknown'} -> ${status}`);
  
  // 广播状态更新到所有相同频道的用户（包括自己，用于多设备同步）
  if (ws.channel) {
    broadcast(ws.channel, {
      type: 'status_update',
      nick: ws.nick || 'guest',
      status: status,
      timestamp: ws.lastStatusUpdate,
      channel: ws.channel
    });
    
    console.log(`📡 状态已广播到 #${ws.channel}: ${ws.nick} (${status})`);
  }
}

module.exports = handleStatusUpdate;

