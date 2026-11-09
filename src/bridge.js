import net from 'node:net';

export function callbackMessage(raw, pending) {
  try {
    const { messageID, customMessage } = JSON.parse(raw);
    if (messageID !== 4 || !pending || customMessage?.requestId !== pending.requestId) return null;
    const { snapshotJson, ...message } = customMessage;
    if (snapshotJson === undefined) return message;
    if (typeof snapshotJson !== 'string') return null;
    return { ...message, snapshot: JSON.parse(snapshotJson) };
  } catch {
    return null;
  }
}

export class Bridge {
  constructor({ callbackPort = 39998, ttsPort = 39999, timeoutMs = 5000 } = {}) {
    this.callbackPort = callbackPort;
    this.ttsPort = ttsPort;
    this.timeoutMs = timeoutMs;
    this.pending = null;
  }

  async start() {
    this.server = net.createServer(socket => {
      let bytes = 0;
      const chunks = [];
      socket.on('data', chunk => {
        bytes += chunk.length;
        if (bytes > 65536) {
          socket.destroy();
          return;
        }
        chunks.push(chunk);
      });
      socket.on('end', () => {
        const message = callbackMessage(Buffer.concat(chunks).toString('utf8'), this.pending);
        if (message && this.pending) this.pending.resolve(message);
      });
      socket.on('error', () => {});
    });
    await new Promise((resolve, reject) => {
      this.server.once('error', reject);
      this.server.listen(this.callbackPort, '127.0.0.1', () => {
        this.server.off('error', reject);
        resolve();
      });
    });
  }

  async request(message) {
    if (this.pending) throw Error('Request already in flight');
    if (!message.requestId) throw Error('Missing request ID');
    return new Promise((resolve, reject) => {
      let settled = false;
      const done = (error, result) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        this.pending = null;
        if (error) reject(error);
        else resolve(result);
      };
      const timer = setTimeout(() => done(Error('Table response timed out')), this.timeoutMs);
      this.pending = { requestId: message.requestId, resolve: value => done(null, value) };
      const socket = net.createConnection({ host: '127.0.0.1', port: this.ttsPort }, () => {
        socket.end(JSON.stringify({ messageID: 2, customMessage: message }));
      });
      socket.on('error', () => done(Error('Table connection failed')));
    });
  }

  close() {
    this.server?.close();
  }
}
