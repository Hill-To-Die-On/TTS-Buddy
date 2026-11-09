export function historyRecord(s,time=new Date().toISOString()) {
 return {time,matchId:s.matchId,revision:s.revision,phase:s.phase,activeSeat:s.activeSeat,scores:{human:s.scores.human,buddy:s.scores.buddy},status:s.status,lastAction:s.lastAction?{seat:s.lastAction.seat,card:s.lastAction.card,effect:s.lastAction.effect}:null,winner:s.winner || null};
}
