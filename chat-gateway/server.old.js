import http from 'http';
import { WebSocketServer } from 'ws';

const server = http.createServer();
const wss = new WebSocketServer({ server, path: '/chat-ws' });

const rooms = new Map(); // channel -> Set<WebSocket>

function broadcast(channel, packet, excludeWs = null) {
  const set = rooms.get(channel);
  if (!set) return;
  const text = JSON.stringify(packet);
  for (const ws of set) {
    // ✅ 排除指定的 WebSocket 连接（通常是发送者自己）
    if (ws === excludeWs) continue;
    
    if (ws.readyState === 1) {  // 1 = WebSocket.OPEN
      try {
        ws.send(text);
      } catch (err) {
        console.error('broadcast send error:', err.message);
      }
    }
  }
}

wss.on('connection', (ws) => {
  ws.isAlive = true;
  ws.on('pong', () => (ws.isAlive = true));

  ws.on('message', (data) => {
    let msg = {};
    try { msg = JSON.parse(data.toString()); } catch { return; }

    // ✅ 兼容 cmd 和 type 两种字段名
    const msgType = msg.type || msg.cmd;
    const channel = msg.room || msg.channel;

    // 处理 nick 命令
    if (msgType === 'nick' && msg.nick) {
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
      if (ws.readyState === 1) {
        try {
          ws.send(JSON.stringify({ 
            type: 'info', 
            text: `昵称已更改为 ${newNick}` 
          }));
        } catch (err) {
          console.error('send nick confirmation error:', err.message);
        }
      }
      return;
    }

    // 处理 join 命令
    if (msgType === 'join' && channel) {
      ws.channel = channel;
      ws.nick = ws.nick || msg.nick || 'guest';
      if (!rooms.has(ws.channel)) rooms.set(ws.channel, new Set());
      rooms.get(ws.channel).add(ws);
      
      // ✅ 广播给频道内其他用户（不包括自己）
      broadcast(ws.channel, {
        type: 'user_joined',
        nick: ws.nick,
        channel: ws.channel
      }, ws);  // 传入 ws 表示排除自己
      
      // 发送确认消息给当前用户
      if (ws.readyState === 1) {
        try {
          ws.send(JSON.stringify({ type: 'info', text: `joined #${ws.channel}` }));
        } catch (err) {
          console.error('send join confirmation error:', err.message);
        }
      }
      return;
    }

    // 处理 who 命令（在线用户列表）
    if (msgType === 'who' && ws.channel) {
      const users = Array.from(rooms.get(ws.channel) || []).map(c => c.nick || 'guest');
      
      if (ws.readyState === 1) {
        try {
          ws.send(JSON.stringify({ 
            type: 'presence', 
            room: ws.channel, 
            users, 
            count: users.length 
          }));
        } catch (err) {
          console.error('send presence error:', err.message);
        }
      }
      return;
    }

    // 处理聊天消息（兼容 'message' 和 'chat'）
    if ((msgType === 'message' || msgType === 'chat') && ws.channel && typeof msg.text === 'string') {
      // ✅ 转发客户端的 id，支持客户端去重
      broadcast(ws.channel, { 
        type: 'message',
        channel: ws.channel,
        nick: ws.nick || 'guest', 
        text: msg.text,
        id: msg.id  // 保留客户端的消息 ID
      });
    }
  });

  ws.on('close', () => {
    if (ws.channel && rooms.get(ws.channel)) {
      // ✅ 广播用户离开通知（在删除之前）
      broadcast(ws.channel, {
        type: 'user_left',
        nick: ws.nick || 'guest',
        channel: ws.channel
      }, ws);  // 排除自己（虽然已经断开）
      
      rooms.get(ws.channel).delete(ws);
      if (rooms.get(ws.channel).size === 0) rooms.delete(ws.channel);
    }
  });
});

setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.isAlive) { try { ws.terminate(); } catch {} ; continue; }
    ws.isAlive = false;
    try { ws.ping(); } catch {}
  }
}, 30000);

server.listen(8080, () => console.log('chat-gateway listening on 8080'));
