-- Native presentation of the H5 typing-feedback rules. Rewarded receipts own heat.
---@class FlameTypingFeedback
---@field app table<string,any>
local F={};F.__index=F
function F.new(app)return setmetatable({app=app,motes={},energy=0,pulse=0,serial=0,since=10,lastBurst=-10,accepted=0,mechanical=0},F)end
function F:clear()self.motes={};self.energy=0;self.pulse=0;self.since=10 end
function F:add(m)if #self.motes>=88 then table.remove(self.motes,1)end;self.motes[#self.motes+1]=m end
function F:press(key,combo,rewarded)
 local a=self.app;local x,y=(a.viewportWidth or 390)*.5,(a.viewportHeight or 844)-30
 for _,h in ipairs(a.ui.hits)do if h.id=='key-'..key then x=h.x+h.w/2;y=h.y+h.h*.3 end end
 self.lastX=x;self.lastY=y;self.serial=self.serial+1
 if not rewarded then self.mechanical=self.mechanical+1;return end
 self.accepted=self.accepted+1;self.since=0;self.energy=math.min(1,math.max(0,combo-1)/26);self.pulse=1
 if a.reduced then return end
 local spread=1+self.energy*.65
 for i=0,5+math.floor(self.energy*5)do local angle=i*2.399+self.serial*.73;local speed=(26+i%4*17)*spread;self:add({x=x,y=y,vx=math.cos(angle)*speed,vy=-42-math.abs(math.sin(angle))*speed,age=0,life=.24+i%3*.085,size=1.4+i%3*.6,turn=angle,kind=i%3==0 and'coal'or'ember'})end
 if key:match('^[a-z0-9]$')then
  local count=0;for _,m in ipairs(self.motes)do if m.kind=='letter'then count=count+1 end end
  if count>=3 then for i,m in ipairs(self.motes)do if m.kind=='letter'then table.remove(self.motes,i);break end end end
  self:add({x=x,y=y-3,vx=(self.serial%2==1 and 1 or-1)*(12+self.energy*15),vy=-82-self.energy*26,age=0,life=.42,size=19+self.energy*7,turn=(self.serial%3-1)*.14,kind='letter',letter=key:upper()})
 end
 self:add({x=x,y=y,vx=0,vy=0,age=0,life=.24,size=18+self.energy*8,turn=0,kind='ring'})
 self:add({x=x,y=y,vx=0,vy=0,age=0,life=.36,size=2,turn=0,kind='flow',startX=x,startY=y})
end
function F:event(e)
 if e.type=='stroke'then if e.key~='Backspace'then self:press(e.key or'',e.combo or 0,e.rewarded==true)end;return end
 if e.type=='qte-error'then self.energy=0;self.errorUntil=self.app.time+.2;return end
 if e.type=='combo-lost'or e.type=='release-miss'then self.energy=0;return end
 local released=e.type=='release'or e.type=='skill'or e.type=='parry';local completed=e.type=='qte'and e.stage=='success'and not(e.qteId or''):match('^release:')
 if not(released or completed)or self.app.time-self.lastBurst<.13 then return end
 self.lastBurst=self.app.time;self.pulse=1.6;if self.app.reduced then return end
 local x,y=self.lastX or(self.app.viewportWidth or 390)*.5,self.lastY or(self.app.viewportHeight or 844)-70
 for i=0,(released and 25 or 14)do local angle=i*2.399+.4;local speed=40+i%6*16;self:add({x=x,y=y,vx=math.cos(angle)*speed,vy=-52-math.abs(math.sin(angle))*speed,age=0,life=.35+i%4*.07,size=1.8+i%3,turn=angle,kind=i%4~=0 and'ember'or'coal'})end
 self:add({x=x,y=y,vx=0,vy=0,age=0,life=.32,size=released and 58 or 34,turn=0,kind='ring'})
end
function F:update(dt)
 if self.app.modal or self.app.state.paused then self:clear();return end
 dt=math.min(.05,dt);self.since=self.since+dt;self.pulse=math.max(0,self.pulse-dt*7)
 if self.app.reduced then self.motes={};return end
 for i=#self.motes,1,-1 do local m=self.motes[i];m.age=m.age+dt;if m.age>=m.life then table.remove(self.motes,i)elseif m.kind~='flow'then m.x=m.x+m.vx*dt;m.y=m.y+m.vy*dt;m.vy=m.vy+(m.kind=='letter'and 35 or 145)*dt end end
end
function F:draw(ui,w,h)
 if self.app.modal or self.app.reduced then return end
 local a,vg=self.app,ui.vg;local mount=a.renderer.heroAttachment;local scale=w/a.worldCanvas.width;local target={x=mount.x*scale,y=mount.y*scale};local seam=(a.worldH or h-246)+8
 for _,m in ipairs(self.motes)do local t=m.age/m.life;local alpha=(1-t)^(m.kind=='letter'and 1 or 1.4);nvgSave(vg)
  if m.kind=='flow'then
  local function point(p)local q=p*p*(3-2*p);local lift=math.sin(p*math.pi)*(24+math.abs(target.x-m.startX)*.1);return m.startX+(target.x-m.startX)*q,m.startY+(target.y-m.startY)*q-lift end
   local ex,ey=point(t);local sx,sy=point(math.max(0,t-.17));nvgGlobalAlpha(vg,math.sin(t*math.pi)*.82);nvgBeginPath(vg);nvgMoveTo(vg,sx,sy);nvgLineTo(vg,ex,ey);nvgStrokeColor(vg,nvgRGBA(242,177,94,255));nvgStrokeWidth(vg,2);nvgStroke(vg);ui:rect(math.floor(ex)-1,math.floor(ey)-1,2,3,'#ffe2a3')
  else
   nvgGlobalAlpha(vg,alpha);nvgTranslate(vg,m.x,m.y)
   if m.kind=='letter'then nvgRotate(vg,m.turn);ui:text(m.letter,0,-m.size/2,m.size*(1+t*.32),'#ffe4a2','center')
   elseif m.kind=='ring'then nvgGlobalAlpha(vg,alpha*.6);nvgBeginPath(vg);nvgEllipse(vg,0,0,m.size*(.2+t*1.3),2+t*5);nvgStrokeColor(vg,nvgRGBA(244,187,101,255));nvgStrokeWidth(vg,1.5);nvgStroke(vg)
   else nvgRotate(vg,m.turn+t*3);ui:rect(-m.size*.5,-m.size*.5,m.size,m.size*(m.kind=='coal'and 1 or 1.9),m.kind=='coal'and'#9c623e'or(t<.3 and'#ffe8ae'or(t<.66 and'#f9af4e'or'#a74f2c')))end
  end;nvgRestore(vg)
 end
end
return F
