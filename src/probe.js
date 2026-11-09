import {Bridge} from './bridge.js';
import {randomUUID} from 'node:crypto';
const b=new Bridge();
try {await b.start(); const a=await b.request({type:'probe',requestId:randomUUID()}); console.log(JSON.stringify(a));} catch(e){console.error(e.message);process.exitCode=1;} finally{b.close();}
