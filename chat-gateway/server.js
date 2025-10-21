import http from 'http';
import { WebSocketServer } from 'ws';

const server = http.createServer();
const wss = new WebSocketServer({ server, path: '/chat-ws' });

const rooms = new Map(); // channel -> Set<WebSocket>

function broadcast(channel, packet) {
  const set = rooms.get(channel);
  if (!set) return;
  const text = JSON.stringify(packet);
  for (const ws of set) if (ws.readyState === ws.OPEN) ws.send(text);
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
      ws.nick = msg.nick;
      return;
    }

    // 处理 join 命令
    if (msgType === 'join' && channel) {
      ws.channel = channel;
      ws.nick = ws.nick || msg.nick || 'guest';
      if (!rooms.has(ws.channel)) rooms.set(ws.channel, new Set());
      rooms.get(ws.channel).add(ws);
      ws.send(JSON.stringify({ type: 'info', text: `joined #${ws.channel}` }));
      return;
    }

    // 处理 who 命令（在线用户列表）
    if (msgType === 'who' && ws.channel) {
      const users = Array.from(rooms.get(ws.channel) || []).map(c => c.nick || 'guest');
      ws.send(JSON.stringify({ 
        type: 'presence', 
        room: ws.channel, 
        users, 
        count: users.length 
      }));
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
