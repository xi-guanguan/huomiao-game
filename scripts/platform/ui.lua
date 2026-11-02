-- Native NanoVG UI: live values, hit regions, authored charcoal surfaces and keyboard.
---@class FlameUI
---@field app table<string,any>
---@field vg NVGContextWrapper
---@field images table<string,integer>
---@field font integer
---@field iconMap table<string,{x:number,y:number,w:number,h:number}>
local U={};U.__index=U
local E=require('core.engine');local Guide=require('core.journey-guide');local Canvas=require('platform.canvas')
local C={ink='#141d1b',bone='#e5dbc0',muted='#a2a48f',fire='#edbc78',dim='#5b6153',red='#d68b63'}
function U.new(app,vg)local self=setmetatable({app=app,vg=vg,images={},hits={},time=0},U);self.font=nvgCreateFont(vg,'flame','Fonts/MiSans-Regular.ttf');assert(self.font>=0,'Chinese font unavailable');return self end
function U:rect(x,y,w,h,c,a)local r,g,b,aa=Canvas.rgba(Canvas.parse(c));nvgBeginPath(self.vg);nvgRect(self.vg,x,y,w,h);nvgFillColor(self.vg,nvgRGBA(r,g,b,(a or 1)*aa));nvgFill(self.vg)end
function U:text(text,x,y,size,color,align,width)
 local vg=self.vg;nvgFontFaceId(vg,self.font);nvgFontSize(vg,size or 14);nvgTextAlign(vg,(align=='center'and NVG_ALIGN_CENTER or align=='right'and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT)+NVG_ALIGN_TOP)
 local r,g,b,a=Canvas.rgba(Canvas.parse(color or C.bone));nvgFillColor(vg,nvgRGBA(r,g,b,a));if width then nvgTextBox(vg,x,y,width,tostring(text),nil)else nvgText(vg,x,y,tostring(text),nil)end
end
function U:image(path,x,y,w,h,alpha,sx,sy,sw,sh)
 local vg=self.vg;local handle=self.images[path];if handle==nil then handle=nvgCreateImage(vg,path,NVG_IMAGE_NEAREST);self.images[path]=handle end;if handle<=0 then return false end
 local iw,ih=nvgImageSize(vg,handle);sx=sx or 0;sy=sy or 0;sw=sw or iw;sh=sh or ih
 nvgSave(vg);nvgIntersectScissor(vg,x,y,w,h);nvgBeginPath(vg);nvgRect(vg,x,y,w,h);nvgFillPaint(vg,nvgImagePattern(vg,x-sx*w/sw,y-sy*h/sh,iw*w/sw,ih*h/sh,0,handle,alpha or 1));nvgFill(vg);nvgRestore(vg);return true
end
function U:skin(name,x,y,w,h,alpha)
 local path='round4/round45/ui/'..name..'.png';local vg=self.vg;local handle=self.images[path];if not handle then self:image(path,x,y,w,h,alpha);handle=self.images[path]end;if not handle or handle<=0 then self:rect(x,y,w,h,C.ink);return end
 local iw,ih=nvgImageSize(vg,handle);local edge=8;local xx={x,x+edge,x+w-edge};local yy={y,y+edge,y+h-edge};local ww={edge,w-edge*2,edge};local hh={edge,h-edge*2,edge};local sx={0,8,iw-8};local sy={0,8,ih-8};local sw={8,iw-16,8};local sh={8,ih-16,8};for j=1,3 do for i=1,3 do if ww[i]>0 and hh[j]>0 then self:image(path,xx[i],yy[j],ww[i],hh[j],alpha,sx[i],sy[j],sw[i],sh[j])end end end
end
function U:icon(name,x,y,w,h)local item=(self.iconMap or{})[name];if item then return self:image('round4/round45/ui/icons.png',x,y,w,h,1,item.x,item.y,item.w,item.h)end;return false end
function U:cover(path,w,h)
 if self.images[path]==nil then self:image(path,0,0,1,1,0)end;local handle=self.images[path];if not handle or handle<=0 then return end
 local iw,ih=nvgImageSize(self.vg,handle);local scale=math.max(w/iw,h/ih);local sw,sh=w/scale,h/scale;self:image(path,0,0,w,h,1,(iw-sw)/2,(ih-sh)/2,sw,sh)
end
function U:contain(path,x,y,w,h,alpha)
 if self.images[path]==nil then self:image(path,0,0,1,1,0)end;local handle=self.images[path];if not handle or handle<=0 then return end
 local iw,ih=nvgImageSize(self.vg,handle);local scale=math.min(w/iw,h/ih);local dw,dh=iw*scale,ih*scale;self:image(path,x+(w-dw)/2,y+(h-dh)/2,dw,dh,alpha)
end
function U:button(id,label,x,y,w,h,fn,primary,disabled)
 local down=self.app.pressed==id and self.app.time-(self.app.pressedAt or-10)<.1;self:skin(primary and 'button-active'or 'button',x,y+(down and 1 or 0),w,h,disabled and .55 or 1);self:text(label,x+w/2,y+h/2-9,15,disabled and C.dim or C.bone,'center');if not disabled then self.hits[#self.hits+1]={id=id,x=x,y=y,w=w,h=h,fn=fn};if self.app.keyboardFocus and self.app.focusIndex==#self.hits then nvgBeginPath(self.vg);nvgRect(self.vg,x+2,y+2,w-4,h-4);nvgStrokeColor(self.vg,nvgRGBA(237,188,120,255));nvgStrokeWidth(self.vg,1);nvgStroke(self.vg)end end
end
function U:bar(x,y,w,h,value,color)self:rect(x,y,w,h,'#111b19');self:rect(x+1,y+1,math.max(0,(w-2)*math.max(0,math.min(1,value))),h-2,color or C.bone)end
function U:tap(x,y)
 for i=#self.hits,1,-1 do local h=self.hits[i];if x>=h.x and y>=h.y and x<h.x+h.w and y<h.y+h.h then self.app.keyboardFocus=false;self.app.pressed=h.id;self.app.pressedAt=self.app.time;h.fn();return true end end;return false
end
function U:worldHud(w,worldH)
 local a,s=self.app,self.app.state;local experienced=s.kills>0 or s.chapter>0 or s.totalSkillPointsEarned>0
 self:text((E.CHAPTERS[s.chapter+1]or{}).name or '余烬',14,20,13);self:button('sound','',w-102,10,40,40,function()a:toggleSound()end);self:icon('sound',w-95,17,26,26);if a.audioMuted then self:text('×',w-83,14,20,C.fire)end;self:button('pause','',w-54,10,40,40,function()a:show('pause')end);self:icon('pause',w-47,17,26,26)
 if s.enemy then self:text(s.enemy.name,w*.15,68,13);self:bar(w*.15,91,w*.73,5,s.enemy.hp/s.enemy.maxHp,C.red);local intent=s.enemy.heavyIntentRemaining or 0;if intent>0 then self:text(string.format('重击将至 · %.1f秒',intent),w*.88,102,12,C.fire,'right')elseif #s.pendingEnemyHits>0 then self:text('攻击已出手',w*.88,102,12,C.fire,'right')end end
 if s.qte then local q=s.qte;self:skin('notice',w*.1,math.max(128,worldH*.32),w*.8,106);self:text(q.label,w*.5,math.max(140,worldH*.32+12),12,C.muted,'center');self:text(q.target,w*.5,math.max(160,worldH*.32+34),21,C.bone,'center');self:text(q.pinyin:sub(q.progress+1),w*.5,math.max(189,worldH*.32+65),18,C.fire,'center')end
 local yy=worldH-93;self:text(string.format('生命力  %d / %d',math.ceil(s.resolve),s.maxResolve),16,yy,13);local f=require('core.hero-form').heroForm(s);local forms={ember='头颅',wraith='凝身',kindled='燃身',ifrit='火鬼'};self:text(forms[f.form],w-16,yy,12,C.muted,'right');self:bar(16,yy+23,w-32,9,s.resolve/s.maxResolve)
 if s.phase=='fallen'then self:text('散成余烬',w*.5,worldH*.47,26,C.bone,'center');self:text('她的声音，还在灰里等你。',w*.5,worldH*.47+40,13,C.muted,'center')end
 if experienced or s.phase=='combat'then self:text(string.format('怒火 %d / 100',math.floor(s.rage)),16,yy+40,12,C.fire);self:text((s.combat or{}).command or'',w-16,yy+40,13,C.fire,'right');self:bar(16,yy+61,w-32,6,s.rage/100,'#bb6436')end
 self:bar(16,worldH-8,w-32,2,s.chapterProgress,'#7f8b70')
 local guide=a.tutorial and a.tutorial.current;if guide and not a.modal and not s.qte then self:skin('notice',w*.06,yy-48,w*.88,38);self:text(guide.text,w*.09,yy-39,12,C.bone,nil,w*.82)end
end
function U:controls(w,y,h)
 local a,s=self.app,self.app.state;self:image('round4/round45/ui/forge-bed.png',0,y,w,h);local skills=Guide.visibleSkills(s);local slotW=(w-82)/math.max(1,#skills)
 for i,id in ipairs(skills)do local d;for _,k in ipairs(E.SKILLS)do if k.id==id then d=k end end;local x=8+(i-1)*slotW;local cooldown=s.cooldowns[id];self:skin('skill-socket',x,y+6,slotW-4,64);self:icon(id,x+5,y+10,24,24);self:text(d.name,x+31,y+14,13);self:text(d.command,x+8,y+37,slotW<105 and 11 or 13,C.fire);self:text(cooldown>0 and string.format('%.1f秒',cooldown)or('生命'..d.lifeCost..' · 怒'..d.cost),x+8,y+55,10,C.muted);if cooldown>0 then self:bar(x+7,y+66,slotW-18,2,1-cooldown/d.cooldown,C.fire)end end
 if s.totalSkillPointsEarned>0 or s.skillPoints>0 then self:button('growth','生长 '..(s.skillPoints>0 and s.skillPoints or''),w-76,y+7,70,62,function()a:show('growth')end)end
 self:text(s.beat.combo>=3 and s.beat.combo..' 连击'or'',12,y+78,12,C.fire);self:button('keyboard','',w-42,y+73,34,25,function()a.keyboardHidden=not a.keyboardHidden end);self:icon('keyboard',w-36,y+74,22,22)
 if a.keyboardHidden then return end
 local top=y+99;local gap=3;local keyW=(w-15-gap*9)/10;local keyH=math.max(30,math.min(42,(h-147)/3));local rows={'qwertyuiop','asdfghjkl','zxcvbnm'}
 for j,row in ipairs(rows)do local count=#row+(j==3 and 2 or 0);local left=(w-count*(keyW+gap)+gap)/2;for i=1,count do local key,label;if j==3 and i==1 then key=',';label='，'elseif j==3 and i==count then key='Backspace';label='删'else local at=i-(j==3 and 1 or 0);key=row:sub(at,at);label=key:upper()end
  local x,yy=left+(i-1)*(keyW+gap),top+(j-1)*(keyH+gap);local pressed=(a.lastKeys[key]or-10)>a.time-.09;local variant=(i+j)%4
  local q=s.qte;local needed=q and q.pinyin:sub(q.progress+1,q.progress+1)==key
  self:image('round4/round45/ui/key-'..variant..(pressed and'-pressed'or'')..'.png',x,yy+(pressed and 1 or 0),keyW,keyH);if needed then self:rect(x+2,yy+keyH-4,keyW-4,2,C.fire)end;self:text(label,x+keyW/2,yy+keyH/2-9,16,(pressed or needed)and'#ffe7ad'or C.bone,'center');self.hits[#self.hits+1]={id='key-'..key,x=x,y=yy,w=keyW,h=keyH,fn=function()a:stroke(key,'touch')end}
 end end
 if s.phase=='combat'or s.kills>0 then self:button('guard','火盾   Space / huodun',8,y+h-44,w-16,38,function()a:stroke(' ','touch')end,false,(s.combat.guardCooldown or 0)>0);if s.combat.guardCooldown>0 then self:text(string.format('%.1f秒',s.combat.guardCooldown),w-24,y+h-32,12,C.muted,'right')end end
end
function U:loading(w,h)
 local a=self.app;self:cover(h/w>1.95 and'round5/loading-390x844.png'or'round5/loading-360x640.png',w,h);self:text('火苗',w*.5,h*.1,60,C.bone,'center');self:text(a.loadError and'余火还没接好。请重试。'or a.loadLabel,w*.5,h*.85,14,C.bone,'center');self:bar(w*.1,h*.91,w*.8,5,a.loadStep/6,C.fire);if a.loadError then self:button('retry','重新准备',w*.25,math.min(h*.93,h-48),w*.5,42,function()a:retryLoad()end,true)end
end
function U:modalView(w,h)
 local a,s=self.app,self.app.state;local page=a.modal;if not page then return end;self.hits={};local vg=self.vg;self:rect(0,0,w,h,'#101b19',.87)
 nvgSave(vg);local t=a.reduced and 1 or math.min(1,a.modalTime/.22);nvgGlobalAlpha(vg,t);nvgTranslate(vg,0,(1-t)*12)
 if page=='title'or page=='story'or page=='ending'then
  local path=page=='title'and'round4/round45/narrative/title-last-ember.png'or'round4/round45/narrative/story-white-cord.png';self:rect(0,0,w,h,'#101b19',.97);self:contain(path,w*.1,h*(page=='title'and .255 or .22),w*.8,h*(page=='title'and .20 or .13),.94)
  if page=='title'then self:text('火苗',w*.5,h*.105,68,C.bone,'center');self:text('火没有停。',w*.5,h*.48,16,C.bone,'center');self:text('你还记得她的声音。',w*.5,h*.48+31,16,C.bone,'center');self:button('begin',a.saved and'继续行走'or'从灰中醒来',w*.18,h*.63,w*.64,48,function()a:begin()end,true);self:button('title-save','存档',w*.3,h*.63+62,w*.4,44,function()a.saveReturn='title';a:show('save')end);self:text('敲键，把身体长回来。',w*.5,h*.86,13,C.muted,'center')
  else local story=E.STORIES[(page=='ending'and #E.STORIES or a.storyIndex+1)]or E.STORIES[1];self:text(story.title,w*.5,h*.14,34,C.bone,'center');self:text(story.text,w*.12,h*.37,17,C.bone,nil,w*.76);self:button('story-next',page=='ending'and'留下这段记忆'or s.phase=='crawl'and'伸出手'or'继续行走',w*.16,h*.79,w*.68,48,function()if page=='ending'then a:exportSave()else a:continueStory()end end,true);if page=='ending'then self:button('ending-save','存档',w*.3,h*.88,w*.4,42,function()a.saveReturn='ending';a:show('save')end)end end
 else
  local x,yy,pw,ph=12,math.max(18,h*.045),w-24,h-math.max(18,h*.045)*2;self:skin('frame',x,yy,pw,ph);local headings={pause='歇一会儿',settings='声音与画面',save='存档',growth='生长',equip='替换一项技能',path='身体会记住'};self:text(headings[page]or'',x+18,yy+21,25);self:button('close','×',w-64,yy+12,40,40,function()a:back()end)
  local cy=yy+79;local bw=pw-40;local bx=x+20
  if page=='pause'then for i,d in ipairs({{'继续行走',function()a:close()end},{'技能与生长',function()a.growthReturn='pause';a:show('growth')end},{'存档',function()a.saveReturn='pause';a:show('save')end},{'声音与画面',function()a:show('settings')end}})do self:button('pause-'..i,d[1],bx,cy+(i-1)*64,bw,50,d[2],i==1)end
  elseif page=='settings'then self:button('mute','声音  '..(a.audioMuted and'已关闭'or'已开启'),bx,cy,bw,52,function()a:toggleSound()end);self:button('motion','震动与闪光  '..(a.reduced and'轻柔'or'标准'),bx,cy+70,bw,52,function()a:setReduced(not a.reduced)end)
  elseif page=='save'then local saved=a.saved or(s.phase~='title'and s or nil);self:text(saved and string.format('%s · %d胜 · %d次续燃',(E.CHAPTERS[saved.chapter+1]or{}).name or'余烬',saved.kills,saved.deaths)or'还没有留下的记忆。',bx,cy,14,C.muted,nil,bw);self:button('export','复制存档',bx,cy+60,bw,48,function()a:exportSave()end,true);self:button('import','从剪贴板接回',bx,cy+124,bw,48,function()a:prepareImport()end);if a.pendingImport then self:text(a.pendingImport.version==1 and'接回旧版收藏，保留当前旅程。'or'接回这份记忆会替换当前旅程。',bx,cy+191,13,C.fire,nil,bw);self:button('confirm-import',a.pendingImport.version==1 and'合并收藏'or'替换并接回',bx,cy+235,bw,48,function()a:importSave()end,true)end
  elseif page=='growth'then self:growth(bx,cy,bw,ph-96)
  elseif page=='path'then for i,step in ipairs(Guide.GROWTH_ROUTE)do self:text(step.name,bx,cy+(i-1)*75,20,C.fire);self:text(step.detail,bx,cy+(i-1)*75+29,13,C.muted,nil,bw)end
  elseif page=='equip'then for i,id in ipairs(s.equipped)do local old;for _,d in ipairs(E.SKILLS)do if d.id==id then old=d end end;self:button('equip-'..i,old.name..'  ←  '..(function()for _,d in ipairs(E.SKILLS)do if d.id==a.selected then return d.name end end end)(),bx,cy+(i-1)*68,bw,52,function()if E.equipSkill(s,a.selected,i-1)then a:feedback('equip');a:persist()end;a:show('growth')end)end end
 end
 nvgRestore(vg)
end
function U:growth(x,y,w,h)
 local a,s=self.app,self.app.state;self:text(s.skillPoints..' 生长点',x,y,13,C.fire);self:button('path','领悟之路',x+w-102,y-7,100,34,function()a:show('path')end)
 local branchW=(w-8)/3;for i,b in ipairs(E.BRANCHES)do local rank=s.upgrades[b.id];local bx=x+(i-1)*(branchW+4);self:button('branch-'..b.id,'',bx,y+36,branchW,49,function()if E.buyUpgrade(s,b.id)then a:feedback('confirm');a:toast(b.levels[s.upgrades[b.id]]);a:persist()end end,s.totalSkillPointsEarned==1 and s.skillPoints==1 and b.id=='adaptation',s.skillPoints<=0 or rank>=3);self:icon(b.id,bx+6,y+43,23,23);self:text(b.name,bx+33,y+43,13,s.skillPoints>0 and C.bone or C.muted);self:text(rank..'/3',bx+33,y+62,11,C.muted)end
 local learned={};local nextSkill
 for _,d in ipairs(E.SKILLS)do if s.skills[d.id]>0 then learned[#learned+1]=d end end
 for _,env in ipairs(E.ENVIRONMENTS)do if env.skill and s.skills[env.skill]==0 then for _,d in ipairs(E.SKILLS)do if d.id==env.skill then nextSkill=d;break end end;if nextSkill then break end end end
 if nextSkill then learned[#learned+1]=nextSkill end
 local sw=w/math.max(1,#learned);for i,d in ipairs(learned)do local bx=x+(i-1)*sw;self:button('node-'..d.id,'',bx,y+91,sw-3,61,function()a.selected=d.id;a:feedback('select')end,a.selected==d.id);self:icon(d.id,bx+(sw-31)/2,y+95,28,28);self:text(d.name,bx+(sw-3)/2,y+128,12,s.skills[d.id]>0 and C.bone or C.muted,'center')end
 local d;for _,def in ipairs(E.SKILLS)do if def.id==a.selected then d=def end end;local rank=s.skills[d.id];local yy=y+164;self:icon(d.id,x,yy-3,32,32);self:text(d.name..'  '..(rank>0 and tostring(rank)..'/3'or'待领悟'),x+43,yy,23);self:text('连续输入 '..d.command,x,yy+32,16,C.fire);self:text('生命 '..d.lifeCost..' · 怒火 '..d.cost..' · 冷却 '..d.cooldown..'秒',x,yy+56,12,C.muted)
 local py=yy+83;local previewH=math.max(80,math.min(123,h-392));if a.drawPreviews then a:drawPreviews(x,py,w,previewH)end
 local unlock={lash='拉开旧围栏时领悟。',headthrow='跨越第一道裂隙时领悟。',oath='在旧祭石前记住声音时领悟。',nova='穿过压住余火的焦木时领悟。'}
 self:text(rank>0 and d.levels[rank]or(unlock[d.id]or d.description),x,py+previewH+13,13,C.bone,nil,w)
 local levels=d.levels --[[@as string[] ]]
 if rank<3 then self:text('下一阶：'..levels[rank+1],x,py+previewH+47,12,C.muted,nil,w)end
 local bottom=y+h-58;self:button('upgrade',rank==0 and'经历中领悟'or(rank>=3 and'已精通'or'强化 · 1点'),x,bottom,w*.49,46,function()if E.upgradeSkill(s,d.id)then a:feedback('confirm');a:persist()end end,true,rank==0 or rank>=3 or s.skillPoints<=0)
 local equipped=false;for _,id in ipairs(s.equipped)do if id==d.id then equipped=true end end;self:button('equip-selected',equipped and'已装备'or'装备',x+w*.51,bottom,w*.49,46,function()a:show('equip')end,false,rank==0 or equipped)
end
function U:render(w,h,dt)
 self.hits={};local a=self.app;local vg=self.vg;self:rect(0,0,w,h,'#0d191c');local width=math.min(w,520);a.offset=(w-width)/2;a.viewportWidth=width;a.viewportHeight=h
 nvgSave(vg);nvgTranslate(vg,a.offset,0);nvgIntersectScissor(vg,0,0,width,h)
 if not a.ready then self:loading(width,h)else
  local controls=a.keyboardHidden and 100 or math.min(290,math.max(246,h*.30));local worldH=h-controls;a.worldH=worldH
  if a.worldHandle then nvgBeginPath(vg);nvgRect(vg,0,0,width,worldH);nvgFillPaint(vg,nvgImagePattern(vg,0,0,width,worldH,0,a.worldHandle,1));nvgFill(vg)end
  if a.modal~='title'and a.modal~='story'and a.modal~='ending'then self:worldHud(width,worldH);self:controls(width,worldH,controls)end
  self:modalView(width,h)
  if a.typing then a.typing:draw(self,width,h)end
 end
 if a.toastTime>0 then self:skin('notice',width*.06,h*.51,width*.88,62);self:text(a.toastText,width*.11,h*.51+12,13,C.bone,nil,width*.78)end
 nvgRestore(vg)
end
function U:dispose()for _,image in pairs(self.images)do if image>0 then nvgDeleteImage(self.vg,image)end end end
return U
