import {readFile,writeFile} from 'node:fs/promises';
// The Signal Run Global script, in load order: rules, the shared tutorial runner, its lessons, then the table.
const parts=['rules.lua','tutorial.lua','signal-run-tutorial.lua','presentation.lua','table.lua'];
const sources=await Promise.all(parts.map(name=>readFile(new URL('../tts/'+name,import.meta.url),'utf8')));
const script=sources.join('\n').replace(/\r\n/g,'\n');
await writeFile(new URL('../tts/Global.lua',import.meta.url),script,'utf8');
const save=JSON.parse(await readFile(new URL('../tts/blank-table.json',import.meta.url),'utf8'));
save.LuaScript=script;
await writeFile(new URL('../tts/Signal Run.json',import.meta.url),JSON.stringify(save,null,2)+'\n','utf8');
