dofile('tts/rules.lua')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local s=Rules.new({'Charge','Boost','Jam','Charge','Boost','Charge'},'test')
eq(#s.hands.human,3); eq(#s.hands.buddy,2); eq(s.active,'human')
local ok=Rules.play(s,'human',1); assert(ok); eq(s.scores.human,1); eq(s.active,'buddy'); eq(s.revision,2)
local jam={matchId='j',revision=1,active='human',phase='playing',scores={human=0,buddy=0},hands={human={'Jam'},buddy={'Charge'}},deck={},lastAction=nil}
assert(Rules.play(jam,'human',1)); eq(jam.scores.human,1); eq(jam.scores.buddy,0)
local boost={matchId='b',revision=1,active='human',phase='playing',scores={human=5,buddy=0},hands={human={'Boost'},buddy={'Charge'}},deck={}}
assert(Rules.play(boost,'human',1)); eq(boost.phase,'finished'); eq(boost.winner,'human')
local ending={matchId='e',revision=1,active='human',phase='playing',scores={human=0,buddy=1},hands={human={'Charge'},buddy={}},deck={}}
assert(Rules.play(ending,'human',1)); eq(ending.phase,'finished'); eq(ending.winner,'draw')
local bad={matchId='x',revision=1,active='buddy',phase='playing',scores={human=0,buddy=0},hands={human={'Charge'},buddy={'Charge'}},deck={}}
assert(not Rules.play(bad,'human',1)); eq(bad.revision,1)
print('Signal Run rules tests passed')
-- Seeded complete matches also check finite progress and valid outcomes.
for seed=1,20 do
  math.randomseed(seed)
  local deck={}; for i=1,8 do deck[#deck+1]='Charge' end; for i=1,6 do deck[#deck+1]='Boost' end; for i=1,4 do deck[#deck+1]='Jam' end
  for i=#deck,2,-1 do local j=math.random(i); deck[i],deck[j]=deck[j],deck[i] end
  local game=Rules.new(deck,'seed-'..seed)
  local turns=0
  while game.phase=='playing' do turns=turns+1; assert(turns<=18); assert(Rules.play(game,game.active,1)) end
  assert(game.winner=='human' or game.winner=='buddy' or game.winner=='draw')
end
print('20 seeded rules-only matches passed')
local jamHit={matchId='hit',revision=3,active='buddy',phase='playing',scores={human=3,buddy=2},hands={human={'Charge'},buddy={'Jam'}},deck={}}
assert(Rules.play(jamHit,'buddy',1)); eq(jamHit.scores.human,2); eq(jamHit.scores.buddy,3); eq(jamHit.lastAction.card,'Jam')
local endWinner={matchId='end',revision=1,active='human',phase='playing',scores={human=2,buddy=4},hands={human={'Charge'},buddy={}},deck={}}
assert(Rules.play(endWinner,'human',1)); eq(endWinner.winner,'buddy')
print('Jam and exhaustion winner checks passed')
local previewState={matchId='preview',revision=9,active='buddy',phase='playing',scores={human=3,buddy=5},hands={human={'Jam'},buddy={'Boost','Jam'}},deck={'Charge'}}
local preview=Rules.preview(previewState,'buddy',1)
eq(preview.scores.buddy,7); eq(preview.scores.human,3); eq(previewState.scores.buddy,5); eq(previewState.revision,9); eq(#previewState.deck,1)
assert(Rules.preview(previewState,'human',1)==nil)
print('Rule preview checks passed')
