import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import test from 'node:test';

test('table build emits the same files from LF and CRLF Lua sources', (t) => {
  const workspace = mkdtempSync(join(tmpdir(), 'tts-buddy-build-'));
  t.after(() => rmSync(workspace, {recursive: true, force: true}));
  const sourceDir = join(workspace, 'src');
  const tableDir = join(workspace, 'tts');
  mkdirSync(sourceDir);
  mkdirSync(tableDir);

  const builder = join(sourceDir, 'build-table.mjs');
  copyFileSync(new URL('../src/build-table.js', import.meta.url), builder);
  writeFileSync(join(tableDir, 'blank-table.json'), JSON.stringify({SaveName: 'Signal Run'}));

  const sources = {
    'rules.lua': 'local rules = {}\n',
    'presentation.lua': 'local presentation = {}\n',
    'table.lua': 'local tableState = {}\n',
  };
  const buildWith = (lineEnding) => {
    for (const [filename, source] of Object.entries(sources)) {
      writeFileSync(join(tableDir, filename), source.replaceAll('\n', lineEnding));
    }
    execFileSync(process.execPath, [builder]);
    return {
      script: readFileSync(join(tableDir, 'Global.lua'), 'utf8'),
      save: readFileSync(join(tableDir, 'Signal Run.json'), 'utf8'),
    };
  };

  const lfBuild = buildWith('\n');
  assert.deepEqual(buildWith('\r\n'), lfBuild, 'table files differ by Lua source line endings');
  assert.equal(lfBuild.script, Object.values(sources).join('\n'));
  assert.deepEqual(JSON.parse(lfBuild.save), {SaveName: 'Signal Run', LuaScript: lfBuild.script});
});
