import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { startLoadingBar } from '../src/startup-progress.js';

test('model loading animates in a terminal and stops when startup settles', t => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  const frames = [];
  let clears = 0;
  const stop = startLoadingBar({
    isTTY: true,
    cursorTo() {},
    clearLine() { clears++; },
    write(frame) { frames.push(frame); },
  });
  assert.match(frames[0], /^\[.*\] Loading model/);
  t.mock.timers.tick(250);
  assert.notEqual(frames[0], frames[1]);
  stop();
  const frameCount = frames.length;
  t.mock.timers.tick(1000);
  assert.equal(frames.length, frameCount);
  assert.equal(clears, 1);
});

test('model loading leaves redirected output free of animation', () => {
  const stop = startLoadingBar({
    isTTY: false,
    write() { assert.fail('A progress frame reached redirected output'); },
  });
  stop();
});

function runLauncher(t, { entry, nodeInstalled = true } = {}) {
  const parent = realpathSync(tmpdir());
  const workspace = mkdtempSync(join(parent, 'tts-buddy-launcher-'));
  t.after(() => {
    const resolved = realpathSync(workspace);
    assert.equal(dirname(resolved), parent);
    rmSync(resolved, { recursive: true });
  });
  copyFileSync(new URL('../start-buddy.cmd', import.meta.url), join(workspace, 'start-buddy.cmd'));
  if (entry) {
    mkdirSync(join(workspace, 'src'));
    writeFileSync(join(workspace, 'src', 'index.js'), entry);
  }
  const systemDir = join(process.env.SystemRoot, 'System32');
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => key.toLowerCase() !== 'path'));
  env.Path = nodeInstalled ? `${dirname(process.execPath)};${systemDir}` : systemDir;
  return spawnSync(join(systemDir, 'cmd.exe'), ['/d', '/c', 'start-buddy.cmd'], {
    cwd: workspace,
    env,
    encoding: 'utf8',
    timeout: 10000,
    windowsHide: true,
  });
}

const windowsOnly = { skip: process.platform !== 'win32' };

test('Windows launcher explains when only the batch file was extracted', windowsOnly, t => {
  const result = runLauncher(t);
  assert.ifError(result.error);
  assert.equal(result.status, 1);
  assert.match(result.stdout + result.stderr, /Extract the entire ZIP/);
  assert.doesNotMatch(result.stdout, /Press Enter/);
});

test('Windows launcher gives a clear message when Node is missing', windowsOnly, t => {
  const result = runLauncher(t, { entry: 'process.exit(0);', nodeInstalled: false });
  assert.ifError(result.error);
  assert.equal(result.status, 1);
  assert.match(result.stdout + result.stderr, /Install Node\.js 24 or newer/);
});

test('Windows launcher retains the error and exit code with redirected output', windowsOnly, t => {
  const result = runLauncher(t, { entry: 'console.error("Model startup failed."); process.exit(7);' });
  assert.ifError(result.error);
  assert.equal(result.status, 7);
  assert.match(result.stdout, /Starting TTS Buddy/);
  assert.match(result.stderr, /Model startup failed/);
  assert.doesNotMatch(result.stdout, /Press Enter/);
});
