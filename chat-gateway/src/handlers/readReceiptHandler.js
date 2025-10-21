// handlers/readReceiptHandler.js
const { broadcast } = require('../services/broadcaster');
const roomManager = require('../services/roomManager');

function handleReadReceipt(ws, msg) {
  const { messageId, channel, userId, timestamp } = msg;
  
  if (!messageId || !channel || !userId || !timestamp) {
    console.warn('⚠️ Invalid read_receipt message:', msg);
    return;
  }
  
  // 广播已读回执给频道中的所有用户（除了发送者自己）
  const roomClients = roomManager.getRoomUsers(channel);
  roomClients.forEach(client => {
    if (client !== ws && client.readyState === 1) {
      try {
        client.send(JSON.stringify({
          type: 'read_receipt',
          messageId: messageId,
          channel: channel,
          userId: userId,
          timestamp: timestamp
        }));
      } catch (e) {
        console.error(`❌ Failed to send read receipt to ${client.nick || 'guest'}: ${e.message}`);
      }
    }
  });
  
  console.log(`✓ 广播已读回执: ${messageId} by ${userId} in #${channel}`);
}

module.exports = handleReadReceipt;

