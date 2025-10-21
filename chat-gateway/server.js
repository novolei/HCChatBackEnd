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

    if (msg.cmd === 'join') {
      ws.channel = msg.channel;
      ws.nick = msg.nick || 'guest';
      if (!rooms.has(ws.channel)) rooms.set(ws.channel, new Set());
      rooms.get(ws.channel).add(ws);
      ws.send(JSON.stringify({ cmd: 'info', text: `joined #${ws.channel}` }));
      return;
    }

    if (msg.cmd === 'chat' && ws.channel && typeof msg.text === 'string') {
      broadcast(ws.channel, { cmd: 'chat', nick: ws.nick, text: msg.text });
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
