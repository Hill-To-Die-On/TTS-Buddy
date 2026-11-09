-- Public, non-authoritative visual markers. The rules remain in Rules/state.
Presentation={}
local pending={}
local labels={}
function presentationNoop() end
local function put(tag,name,position,color,label)
  labels[tag]=label
  local existing=getObjectsWithTag(tag)
  if #existing>0 then
    existing[1].editButton({index=0,label=label})
  elseif not pending[tag] then
    pending[tag]=true
    spawnObject({type='BlockSquare',position=position,scale={1.8,0.15,2.5},callback_function=function(obj)
      obj.addTag(tag); obj.setName(name); obj.setLock(true); obj.setColorTint(color)
      obj.createButton({click_function='presentationNoop',function_owner=Global,label=labels[tag],position={0,0.55,0},rotation={0,180,0},width=0,height=0,font_size=230,font_color={1,1,1}})
      pending[tag]=nil
    end})
  end
end
function Presentation.update(s)
  if not s then return end
  local last=s.lastAction and (string.upper(s.lastAction.seat)..'\n'..s.lastAction.card) or 'LAST\n—'
  put('tts-buddy-deck','Signal Run draw pile (display only)',{-3,1,5},{0.12,0.24,0.43},'DECK\n'..#s.deck)
  put('tts-buddy-last','Signal Run last played card (display only)',{3,1,5},{0.35,0.16,0.22},last)
end
