import { randomUUID } from 'node:crypto';
import { validateSnapshot } from './player.js';

export class Session {
  constructor(bridge, choose, onSnapshot = () => {}, { explain } = {}) {
    this.bridge = bridge;
    this.choose = choose;
    this.onSnapshot = onSnapshot;
    this.explain = explain;
    this.taught = new Set();
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
      if (snapshot.status === 'tutorial') {
        await this.teach(snapshot.tutorial, generation);
        return;
      }
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

  // One explanation per tutorial step. A failure just leaves the lesson text on its own,
  // so it neither pauses Buddy nor retries.
  async teach(step, generation) {
    const key = `${step.id}:${step.stepId}`;
    if (!this.explain || this.taught.has(key)) return;
    this.taught.add(key);
    let text;
    try {
      text = await this.explain(step);
    } catch {
      return;
    }
    if (!text || this.generation !== generation || this.mode !== 'running') return;
    try {
      await this.bridge.request({ protocol: 1, type: 'teach', requestId: randomUUID(), stepId: step.stepId, text });
    } catch {
      // The table keeps showing the lesson text.
    }
  }
}
