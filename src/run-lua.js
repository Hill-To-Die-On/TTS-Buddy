import {spawnSync} from 'node:child_process';
for (const [file,marker] of [['test/rules.lua','Rule preview checks passed'],['test/table.lua','Paired hidden state and guessed ID checks passed'],['test/presentation.lua','Physical marker presentation tests passed']]) {
 const result=spawnSync(process.execPath,['node_modules/fengari-node-cli/src/lua-cli.js',file],{encoding:'utf8'});
 process.stdout.write(result.stdout || ''); process.stderr.write(result.stderr || '');
 if(result.error || result.status!==0 || !(result.stdout || '').includes(marker)) process.exit(1);
}
