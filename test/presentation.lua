local objects={}
Global={}
function getObjectsWithTag(tag) return objects[tag] and {objects[tag]} or {} end
function spawnObject(spec)
 assert(spec.position[3]==5)
 local obj={}
 function obj.addTag(tag) objects[tag]=obj end
 function obj.setLock(v) assert(v) end
 function obj.setName(name) obj.name=name end
 function obj.setColorTint(c) end
 function obj.createButton(button) assert(button.rotation[2]==180); obj.label=button.label end
 function obj.editButton(button) obj.label=button.label end
 spec.callback_function(obj)
 return obj
end
dofile('tts/presentation.lua')
Presentation.update({deck={'secret','secret'},lastAction={seat='human',card='Boost'}})
assert(objects['tts-buddy-deck'].label=='DECK\n2')
assert(objects['tts-buddy-last'].label=='HUMAN\nBoost')
Presentation.update({deck={'secret'},lastAction={seat='buddy',card='Jam'}})
assert(objects['tts-buddy-deck'].label=='DECK\n1')
assert(objects['tts-buddy-last'].label=='BUDDY\nJam')
print('Physical marker presentation tests passed')
