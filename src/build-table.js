import {readFile,writeFile} from 'node:fs/promises';
const rules=await readFile(new URL('../tts/rules.lua',import.meta.url),'utf8');
const presentation=await readFile(new URL('../tts/presentation.lua',import.meta.url),'utf8');
const table=await readFile(new URL('../tts/table.lua',import.meta.url),'utf8');
const script=`${rules}\n${presentation}\n${table}`;
await writeFile(new URL('../tts/Global.lua',import.meta.url),script,'utf8');
const save=JSON.parse(await readFile(new URL('../tts/blank-table.json',import.meta.url),'utf8'));
save.LuaScript=script;
await writeFile(new URL('../tts/Signal Run.json',import.meta.url),JSON.stringify(save,null,2)+'\n','utf8');
