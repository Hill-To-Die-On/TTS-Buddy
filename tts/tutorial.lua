-- Game-agnostic tutorial runner. Each game registers its own ordered lessons. A lesson has an id, a title,
-- short rules text and an optional hint. A practice lesson also has setup(), which builds a practice
-- position, and try(practice, action), which applies the learner's move with that game's own rules and
-- returns applied, outcome ('correct', 'wrong' or 'continue') and feedback. The tutorial state holds only
-- plain data, so a table can save it.
Tutorial = {lessons={}}
local NOTE_LIMIT = 280

function Tutorial.register(game, lessons) Tutorial.lessons[game] = lessons end
local function lessons(t) return Tutorial.lessons[t.game] or {} end
local function lesson(t) if t.status=='teaching' then return lessons(t)[t.step] end end
local function enter(t)
  local l = lesson(t)
  t.practice = l and l.setup and l.setup() or nil
  t.practiceDone = false; t.feedback = nil; t.note = nil
  t.revision = t.revision+1
end

function Tutorial.start(game, id)
  if #(Tutorial.lessons[game] or {})==0 then return nil end
  local t = {game=game, id=id, step=1, status='teaching', revision=0}
  enter(t)
  return t
end

function Tutorial.view(t)
  local total = #lessons(t)
  local l = lesson(t)
  if not l then return {game=t.game, id='complete', step=total, total=total, status='complete', needsPractice=false, practiceDone=true} end
  return {game=t.game, id=l.id, step=t.step, total=total, title=l.title, text=l.text, hint=l.hint,
    needsPractice=l.try~=nil, practiceDone=t.practiceDone, feedback=t.feedback, note=t.note, status=t.status}
end

function Tutorial.next(t)
  local l = lesson(t)
  if not l or (l.try and not t.practiceDone) then return false end
  if t.step>=#lessons(t) then
    t.status = 'complete'; t.practice = nil; t.feedback = nil; t.note = nil; t.revision = t.revision+1
  else
    t.step = t.step+1; enter(t)
  end
  return true
end

function Tutorial.attempt(t, action)
  local l = lesson(t)
  if not l or not l.try or t.practiceDone then return false end
  local applied, outcome, feedback = l.try(t.practice, action)
  if not applied then return false end
  t.feedback = feedback
  if outcome=='correct' then t.practiceDone = true
  elseif outcome=='wrong' then t.practice = l.setup and l.setup() or nil end
  t.revision = t.revision+1
  return true
end

-- Buddy may add a friendlier explanation of the current step. It's kept as one line of plain text,
-- shown beside the lesson text rather than instead of it.
function Tutorial.setNote(t, stepId, text)
  local l = lesson(t)
  if not l or l.id~=stepId or type(text)~='string' then return false end
  text = string.gsub(text, '%c', ' ')
  text = string.gsub(text, '%s+', ' ')
  text = string.match(text, '^%s*(.-)%s*$')
  if text=='' then return false end
  t.note = string.sub(text, 1, NOTE_LIMIT); t.revision = t.revision+1
  return true
end
