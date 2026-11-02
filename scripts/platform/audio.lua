-- Native port of h5/src/sound.ts. Sounds and event ownership stay with GameAudio.
-- Call update(state, realFrameDt) even while the game state is paused.
local Audio = {}; Audio.__index = Audio
local GENERATED = {'key','contact','fracture','reknit','parry','burst','guard','threat','heavy','ui-page','ui-select','ui-toggle','ui-equip','ui-back','ui-confirm'}
local ORIGINAL = {'music-journey','music-boss','music-chase','amb-wind','amb-embers','amb-camp','key','word','head-launch','head-land','rebirth','lash','oath','enemy-hit','arrow','binding','earth','thunder','boss-sweep','break','fallen','upgrade','footstep-grass','footstep-ash'}
local LOOP_NAMES = {['music-journey']=true,['music-boss']=true,['music-chase']=true,['amb-wind']=true,['amb-embers']=true,['amb-camp']=true}
local UNUSED = {fist=true,nova=true}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function fallback(v,d) if v==nil then return d end return v end
local function codepoint(text)
 local a,b,c,d=string.byte(text or '',1,4);if not a then return 0 end
 if a<128 then return a elseif a<224 and b then return (a-192)*64+b-128 elseif a<240 and b and c then return (a-224)*4096+(b-128)*64+c-128 elseif b and c and d then return (a-240)*262144+(b-128)*4096+(c-128)*64+d-128 end
 return a
end
local function remember(set,queue,key,limit)
 if set[key] then return false end;set[key]=true;queue[#queue+1]=key
 if #queue>limit then set[table.remove(queue,1)]=nil end;return true
end
function Audio.new()
 return setmetatable({root=Node(),sounds={},assets={},readyDone=false,disposed=false,clock=0,muted=false,
  pools={effect={},key={},cue={},ui={}},loops={},fading={},lastKey=-math.huge,lastRewardedKey=-math.huge,lastUi=-math.huge,
  pitchCharge=0,duckUntil=0,lastEvent=nil,seenStrings={},stringOrder={},seenContacts={},contactOrder={},latestState=nil},Audio)
end
function Audio:ready(manifest)
 assert(not self.disposed,'Audio has been disposed');self:reset();self.sounds={};self.assets={}
 local paths={};for _,name in ipairs(ORIGINAL) do paths[name]='audio/'..name..'.mp3' end
 for _,kind in ipairs(GENERATED) do paths['r4-'..kind]='audio/r4-'..kind..'.wav' end
 for name,url in pairs(manifest or {}) do
  if not UNUSED[name] and not paths[name] then paths[name]=url:gsub('^%./',''):gsub('^/',''):gsub('^assets/','') end
 end
 for name,url in pairs(paths) do
  local sound=cache:GetResource('Sound',url);assert(sound,'Sound missing: '..url)
  sound:SetLooped(LOOP_NAMES[name]==true);self.sounds[name]=sound;self.assets[name]=url
 end
 self.readyDone=true;return true
end
function Audio:_apply(voice)
 voice.source:SetGain(clamp(voice.gain,0,1)*(self.muted and 0 or 1))
end
function Audio:_voice(name,volume,loop,rate)
 local sound=self.sounds[name];if not self.readyDone or not sound or self.disposed then return nil end
 local node=self.root:CreateChild('AudioVoice')
 local source=node:CreateComponent('SoundSource')
 source:SetSoundType(loop and 'Music' or 'Effect')
 local voice={node=node,source=source,name=name,gain=clamp(volume,0,1),target=clamp(volume,0,1),tau=0,loop=loop}
 -- Play takes absolute Hz. A playback multiplier is never passed as frequency.
 source:Play(sound,sound:GetFrequency()*(rate or 1),voice.gain*(self.muted and 0 or 1))
 return voice
end
function Audio:_stop(voice)
 if voice.stopped then return end;voice.stopped=true;voice.source:Stop();self.root:RemoveChild(voice.node)
end
function Audio:_cleanPool(pool)
 for i=#pool,1,-1 do local v=pool[i];if not v.source:IsPlaying() then self:_stop(v);table.remove(pool,i) end end
end
function Audio:_oneShot(name,volume,rate,lane)
 if self.muted or not self.readyDone or not self.sounds[name] then return end
 lane=lane or (name=='key' and 'key' or 'effect');local pool=self.pools[lane];self:_cleanPool(pool)
 local limit=(lane=='key' or lane=='ui') and 2 or lane=='cue' and 4 or 10
 if #pool>=limit then self:_stop(table.remove(pool,1)) end
 local v=self:_voice(name,volume,false,rate or 1);if v then pool[#pool+1]=v end
end
function Audio:_ramp(voice,target,tau)
 voice.target=target;voice.tau=tau
end
function Audio:_duck(seconds)
 if self.muted or not self.readyDone then return end
 self.duckUntil=math.max(self.duckUntil,self.clock+seconds)
 for _,v in ipairs(self.fading) do self:_ramp(v,0,.025) end
 if self.latestState then self:update(self.latestState,0) end
end
function Audio:key(key,combo,rewarded)
 if self.muted or not self.readyDone or self.clock-self.lastKey<.08 then return end
 self.lastKey=self.clock
 if rewarded==false then self:_oneShot('key',.032,.84,'key');return end
 local energy=tonumber(combo) or 0;energy=finite(energy) and clamp(energy,0,40) or 0
 local gap=self.clock-self.lastRewardedKey;self.pitchCharge=gap>2 and 0 or math.max(0,self.pitchCharge-gap*2)
 self.pitchCharge=math.min(32,energy,self.pitchCharge+1);self.lastRewardedKey=self.clock
 ---@type number[]
 local rates={.92,.96,1};local rate=rates[codepoint(key)%3+1]
 self:_oneShot('r4-key',.3+math.min(28,energy)*.002,rate*(1+self.pitchCharge*.009),'key')
end
function Audio:play(name,volume) self:_oneShot(name,volume or .28) end
function Audio:ui(action)
 if not self.readyDone or self.muted or self.clock-self.lastUi<.07 then return end
 self.lastUi=self.clock
 self:_oneShot('r4-ui-'..action,action=='equip' and .34 or action=='confirm' and .32 or action=='page' and .24 or .26,1,'ui')
end
function Audio:event(event)
 local id=event.id
 if type(id)=='number' then if self.lastEvent~=nil and id<=self.lastEvent then return end;self.lastEvent=id
 else assert(type(id)=='string','Audio event requires a numeric or string receipt');if not remember(self.seenStrings,self.stringOrder,id,2048) then return end end
 local kind=event.type
 if kind=='stroke' then if event.key~='Backspace' then self:key(event.key or '',tonumber(event.combo) or 0,event.rewarded~=false) end
 elseif kind=='semantic' then self:play('word',.12)
 elseif kind=='skill' then
  local names={headthrow='head-launch',rebirth='r4-reknit',lash='lash',nova='r4-burst',oath='oath'};local name=names[event.skill];if name then self:play(name,.24) end
 elseif kind=='hit' then
  if event.source=='burn' or not finite(event.amount) or event.amount<=0 then return end
  local receipt=tostring(fallback(event.attackId,id));if not remember(self.seenContacts,self.contactOrder,receipt,512) then return end
  if event.skill=='nova' then return end
  local combo=self.latestState and self.latestState.beat and self.latestState.beat.combo or 0
  self:_oneShot('r4-contact',event.source=='stroke' and .38 or .46,.94+math.min(30,combo)*.003)
 elseif kind=='telegraph' then self:_oneShot(event.heavy==true and 'r4-heavy' or 'r4-threat',.48,1,'cue');self:_duck(event.heavy==true and .6 or .4)
 elseif kind=='release' then if not event.skill then self:_oneShot('oath',.12,1.12,'cue') end;self:_duck(.7)
 elseif kind=='kill' then self:_oneShot(event.kind=='boss' and 'oath' or 'break',event.kind=='boss' and .2 or .16,.85,'cue');self:_duck(event.kind=='boss' and .8 or .45)
 elseif kind=='player-hit' then if finite(event.amount) and event.amount>0 then self:_oneShot('r4-contact',.38,.78) end
 elseif kind=='impact' then if event.skill=='headthrow' and event.stage=='land' then self:play('head-land',.2) elseif event.source=='environment' then self:play('break',.15) end
 elseif kind=='break' then self:_oneShot('r4-fracture',.5,1,'cue');self:_duck(.25)
 elseif kind=='self-cost' then if type(event.amount)=='number' and event.amount>0 then self:_oneShot('r4-fracture',.13,.8) end
 elseif kind=='guard' then if event.stage=='start' then self:_oneShot('r4-guard',.3,1,'cue') elseif event.stage=='block' then self:_oneShot('r4-guard',.38,.72,'cue') end
 elseif kind=='parry' then self:_oneShot('r4-parry',.55,1,'cue');self:_duck(.4)
 elseif kind=='surge' then if event.stage=='start' then self:_oneShot('r4-reknit',.34,1,'cue') end
 elseif kind=='interrupt' then self:_duck(.22)
 elseif kind=='world-burn' then self:_duck(.6)
 elseif kind=='frenzy' then if event.stage=='start' then self:_oneShot('binding',.12,.85,'cue');self:_duck(.5) end
 elseif kind=='fall' then self:play('fallen',.25);self:_duck(.8)
 elseif kind=='respawn' then self:play('rebirth',.25)
 elseif kind=='unlock' then self:play('upgrade',.18)
 elseif kind=='enemy-attack' then local names={stone='earth',thunder='thunder',binding='binding',arrow='arrow',pyre='boss-sweep',['pyre-combo']='binding'};self:play(names[tostring(event.ability)] or 'enemy-hit',.22)
 elseif kind=='qte' then
  local release=type(event.qteId)=='string' and event.qteId:sub(1,8)=='release:'
  if release and event.stage=='start' then self:_oneShot('key',.12,1.4,'cue');self:_duck(.45) elseif not release and event.stage=='success' then self:_oneShot('oath',.14,1,'cue');self:_duck(.25) end
 elseif kind=='footstep' then
  local terrain=tostring(event.terrain or '')
  local name=(terrain:find('ash',1,true) or terrain:find('灰',1,true) or terrain:find('焦',1,true) or terrain:find('土',1,true)) and 'footstep-ash' or 'footstep-grass'
  local s=self.latestState or {};local vitality=fallback(s.resolve,100)/math.max(1,fallback(s.maxResolve,100))
  if vitality>.16 then self:play(name,(event.motion=='crawl' and .035 or .065)*(vitality<.48 and .45 or 1)) end
 end
end
function Audio:_loop(slot,name,volume)
 if not self.readyDone then return end
 local current=self.loops[slot]
 if not current or current.name~=name then
  if current then self:_ramp(current,0,.18);current.stopAt=self.clock+.8;self.fading[#self.fading+1]=current;self.loops[slot]=nil end
  current=self:_voice(name,0,true,1);if not current then return end;self.loops[slot]=current
 end
 local ducked=(slot=='music' or slot=='embers') and self.clock<self.duckUntil
 current.baseVolume=volume;current.slot=slot;self:_ramp(current,volume*(ducked and .28 or 1),ducked and .018 or .2)
end
function Audio:_advance(dt)
 for _,pool in pairs(self.pools) do self:_cleanPool(pool) end
 local function ramp(v)
  if v.tau>0 then v.gain=v.target+(v.gain-v.target)*math.exp(-dt/v.tau) else v.gain=v.target end;self:_apply(v)
 end
 for _,v in pairs(self.loops) do ramp(v) end
 for i=#self.fading,1,-1 do local v=self.fading[i];if self.clock>=v.stopAt then self:_stop(v);table.remove(self.fading,i) else ramp(v) end end
end
function Audio:update(state,dt)
 assert(not self.disposed,'Audio has been disposed');dt=dt or 0;assert(finite(dt) and dt>=0,'Audio update needs a nonnegative real frame delta')
 self.clock=self.clock+dt;self.latestState=state;if not self.readyDone then return end
 local quiet=state.paused and .4 or 1;local combat=state.phase=='combat' and state.encounterStage~='exit'
 local fury=clamp(fallback(state.rage,0)/100,0,1);local vitality=clamp(fallback(state.resolve,0)/math.max(1,fallback(state.maxResolve,100)),0,1)
 local body=vitality<=.16 and .06 or vitality<.48 and .38 or 1
 local boss=combat and state.enemy and state.enemy.kind=='boss'
 local music=boss and 'music-boss' or combat and self.assets['music-chase'] and 'music-chase' or 'music-journey'
 local musicLevel=state.phase=='title' and .1 or state.phase=='fallen' and .055 or state.phase=='rest' and .12 or combat and ((boss and .165 or .14)+body*.022) or .14
 self:_loop('music',music,musicLevel*quiet);self:_loop('wind','amb-wind',(combat and .024 or .045)*quiet)
 local fire=vitality<=0 and 0 or .004+.036*body+.018*fury*body+(state.infernoActive and .014 or 0)
 self:_loop('embers','amb-embers',fire*quiet);self:_loop('camp','amb-camp',(state.phase=='rest' and .06 or 0)*quiet)
 self:_advance(dt)
end
function Audio:setMuted(value)
 self.muted=value==true
 for _,pool in pairs(self.pools) do for _,v in ipairs(pool) do self:_apply(v) end end
 for _,v in pairs(self.loops) do self:_apply(v) end;for _,v in ipairs(self.fading) do self:_apply(v) end
end
function Audio:reset()
 for _,pool in pairs(self.pools) do for _,v in ipairs(pool) do self:_stop(v) end end;self.pools={effect={},key={},cue={},ui={}}
 for _,v in pairs(self.loops) do self:_stop(v) end;self.loops={};for _,v in ipairs(self.fading) do self:_stop(v) end;self.fading={}
 self.lastEvent=nil;self.seenStrings={};self.stringOrder={};self.seenContacts={};self.contactOrder={};self.lastKey=-math.huge;self.lastRewardedKey=-math.huge;self.lastUi=-math.huge;self.pitchCharge=0;self.duckUntil=0;self.latestState=nil
end
function Audio:dispose()
 if self.disposed then return end;self:reset();self.sounds={};self.assets={};self.readyDone=false;self.root:RemoveAllChildren();self.root=nil;self.disposed=true
end
return Audio
