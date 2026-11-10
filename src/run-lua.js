import {spawnSync} from 'node:child_process';
for (const [file,marker] of [['test/rules.lua','Rule preview checks passed'],['test/table.lua','Signal Run tutorial table tests passed'],['test/presentation.lua','Physical marker presentation tests passed'],['test/tutorial.lua','Flamme Rouge tutorial tests passed'],['test/flamme-rouge.lua','20 seeded Flamme Rouge races passed']]) {
 const result=spawnSync(process.execPath,['node_modules/fengari-node-cli/src/lua-cli.js',file],{encoding:'utf8'});
 process.stdout.write(result.stdout || ''); process.stderr.write(result.stderr || '');
 if(result.error || result.status!==0 || !(result.stdout || '').includes(marker)) process.exit(1);
}
