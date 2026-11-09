import { randomUUID } from 'node:crypto';
import { validateSnapshot } from './player.js';

export class Session {
  constructor(bridge, choose, onSnapshot = () => {}) {
    this.bridge = bridge;
    this.choose = choose;
    this.onSnapshot = onSnapshot;
    this.mode = 'running';
    this.generation = 0;
  }

  pause() {
    this.mode = 'paused';
    this.generation++;
  }

  resume() {
    this.mode = 'running';
    this.generation++;
  }

  async turn() {
    if (this.mode !== 'running') return;
    const generation = this.generation;
    try {
      const inspection = await this.bridge.request({
        protocol: 1, type: 'inspect', requestId: randomUUID(),
      });
      const snapshot = validateSnapshot(inspection.snapshot);
      this.onSnapshot(snapshot);
      if (this.generation !== generation || this.mode !== 'running' ||
          snapshot.phase !== 'playing' || snapshot.activeSeat !== 'buddy' ||
          snapshot.status !== 'running') return;

      const actionId = await this.choose(snapshot);
      if (this.generation !== generation || this.mode !== 'running') return;
      if (!snapshot.legalActions.includes(actionId)) throw Error('Invalid decision');

      const result = await this.bridge.request({
        protocol: 1, type: 'play', requestId: randomUUID(),
        matchId: snapshot.matchId, revision: snapshot.revision, actionId,
      });
      if (result.result !== 'applied') this.pause();
    } catch {
      this.pause();
    }
  }
}
