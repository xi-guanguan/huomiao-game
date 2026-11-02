-- Fire / fifth journey. This entry runs directly in the official Maker UrhoX Runtime.
cjson=require('cjson')
local E=require('core.engine');local JSON=require('core.v2json')
---@type FlameCanvasModule
local Canvas=require('platform.canvas')
local UI=require('platform.ui');local Storage=require('platform.storage');local Previews=require('platform.previews')
local Render=require('render.renderer');local Lib=require('render.lualib_bundle')
---@type table<string,any> Native adapters attach their own live UI and renderer fields.
local App={relayConfirmed=false,gameStarted=false,state=E.createGame(1101),ready=false,loadStep=0,loadLabel='接住这一点余火…',time=0,lastKeys={},lastEvent=0,modalTime=0,toastTime=0,selected='spark',storyIndex=0,audioMuted=false,reduced=false,saveTimer=0,stats={updates=0,renders=0,worldFrames=0,maxMs=0,totalMs=0},testMode=HUOMIAO_TEST_MODE==true}
HUOMIAO=App
local function writeFile(path,text)local file=File(path,FILE_WRITE);assert(file:IsOpen(),'Cannot open '..path);file:WriteLine(text);file:Close()end
function App:toast(text)self.toastText=text;self.toastTime=2.4 end
function App:feedback(name)if self.audio then self.audio:ui(name)end end
function App:releasePreviews()if self.preview then self.preview:dispose();self.preview=nil end end
function App:drawPreviews(x,y,w,h)
 if self.preview then self.preview:draw(self.ui,x,y,w,h)end
end
function App:show(page)
 if self.typing then self.typing:clear()end
 E.clearCombatCommand(self.state);self.modal=page;self.modalTime=0;self.state.paused=true;self.pressed=nil;self.focusIndex=1;self:feedback('page')
 if page~='growth'then self:releasePreviews()end
end
function App:close()self:releasePreviews();self.modal=nil;self.state.paused=false;self.modalTime=0;E.clearCombatCommand(self.state)end
function App:back()
 if self.modal=='growth'then self:show(self.growthReturn or'pause')elseif self.modal=='settings'then self:show('pause')elseif self.modal=='save'then self:show(self.saveReturn or'pause')elseif self.modal=='path'or self.modal=='equip'then self:show('growth')elseif self.modal~='title'and self.modal~='story'and self.modal~='ending'then self:close()end
end
function App:begin()
 if self.saved then local clean=E.restoreGame(self.saved);assert(clean,'Saved journey invalid');self.state=clean;self.saved=nil;self.lastEvent=clean.eventSerial;self.renderer:reset();self.audio:reset();self:close();if clean.phase=='rest'then self.storyIndex=math.min(4,clean.chapter+1);self:show('story')elseif clean.phase=='ending'then self:show('ending')end
 else self:close();E.advance(self.state);self.storyIndex=0;self:show('story')end
end
function App:continueStory()local was=self.state.phase;self:close();if was=='rest'then E.advance(self.state)end;self:persist()end
function App:toggleSound()self.audioMuted=not self.audioMuted;if self.audio then self.audio:setMuted(self.audioMuted)end end
function App:setReduced(value)self.reduced=value==true;if self.renderer then self.renderer:setReducedMotion(self.reduced)end;if self.typing then self.typing:clear()end end
function App:persist()
 if self.testMode or not self.store or self.state.phase=='title'then return end
 local ok,err=pcall(function()self.store:save(self.state,self.words)end)
 if not ok then print('SAVE_FAILURE '..tostring(err));self:toast('这段记忆没有保存成功，请稍后重试。')end
end
function App:exportSave()
 local text=self.store:export(self.saved or(self.state.phase~='title'and self.state or nil),self.words);GetUI():SetClipboardText(text);writeFile(self.store.path..'.export.json',text);self:toast('记忆已复制，也已保存在本机。')
end
function App:prepareImport()
 local ok,pending=pcall(function()return self.store:prepareImport(GetUI():GetClipboardText())end)
 if not ok then self:toast(pending);return end
 if pending.game then local restored=E.restoreGame(pending.game);if not restored then self:toast('这份记忆无法接回，请重新复制完整存档。');return end;pending.game=restored end
 self.pendingImport=pending
end
function App:importSave()
 local pending=self.pendingImport;if not pending then return end
 local ok,state,words=pcall(function()return self.store:applyImport(pending,self.saved or self.state,self.words)end)
 if not ok then self:toast(state);return end
 self.words=words;self.pendingImport=nil
 if pending.version==1 then self:toast('旧版收藏已接回。');return end
 self.state=state or E.createGame(1101);self.saved=nil;if state and self.tutorial then self.tutorial:finish()end;self.lastEvent=self.state.eventSerial;self.renderer:reset();self.audio:reset();self:close();self:persist();self:toast('记忆已接回。')
 if self.state.phase=='title'then self:show('title')end
 if self.state.phase=='rest'then self.storyIndex=math.min(4,self.state.chapter+1);self:show('story')elseif self.state.phase=='ending'then self:show('ending')end
end
function App:stroke(key,source)
 if not self.ready or self.modal or self.state.paused then return false end
 self.strokeSerial=(self.strokeSerial or 0)+1;self.lastKeys[key]=self.time
 if key==' 'and self.state.phase=='combat'and self.state.encounterStage=='active'then return E.castGuard(self.state)end
 return E.stroke(self.state,{id='native-'..self.strokeSerial,key=key,source=source or'physical'})
end
function App:retryLoad()if self.ready then return end;self.loadError=nil;self.loadStep=0;self.loadLabel='重新接回余火…';if self.renderer then Canvas.disposeRenderer(self.renderer,self.vg);self.renderer=nil end;if self.worldCanvas then Canvas.dispose(self.worldCanvas,self.vg);self.worldCanvas=nil;self.worldHandle=nil end;if self.audio then self.audio:dispose();self.audio=nil end end
function App:loadNext()
 if not self.relayConfirmed or not self.gameStarted then return end
 local step=self.loadStep+1
 print('FIFTH_LOAD_STAGE '..step)
 if step==1 then
  self.store=Storage.new({testMode=self.testMode});local saved,words
  if self.testMode then saved=nil;words=JSON.parse('[]')else saved,words=self.store:load()end
  self.saved=saved and assert(E.restoreGame(saved),'Saved journey cannot be restored')or nil;self.words=words;self.tutorial=require('platform.onboarding').new(self.saved,self.store.path..'.intro-v1.json',self.testMode);self.loadLabel='接回记忆…'
 elseif step==2 then self.manifest=require('platform.native'):json('round4/art/manifest.json');self.baseManifest=require('platform.native'):json('manifest.json');self.ui.iconMap=require('platform.native'):json('round4/round45/ui/ui-manifest.json').icons;self.loadLabel='余烬正在聚拢…'
 elseif step==3 then
  self.worldCanvas=Canvas.new(192,280);self.renderer=Lib.__TS__New(Render.GameRenderer,self.worldCanvas);Canvas.enableRenderer(self.renderer,self.worldCanvas);self.renderer:setAssets(self.manifest);self.loadLabel='身体接回了火…'
 elseif step==4 then
  self.audio=require('platform.audio').new();local assets={};for k,v in pairs(self.baseManifest.audio or{})do assets[k]=v end;for k,v in pairs(self.manifest.audio or{})do assets[k]=v end;self.audio:ready(assets);self.audio:setMuted(self.audioMuted);self.loadLabel='听见了炉火…'
 elseif step==5 then self.strokeSerial=0;self.loadLabel='敲键，就能醒来。'
 elseif step==6 then self.renderer:render(self.state,0);self.worldHandle=Canvas.upload(self.worldCanvas,self.vg);self.ready=true;self:show('title');self.loadLabel='余火已醒。';print('FIFTH_JOURNEY_READY nativeLua=true')end
 self.loadStep=step
end
function App:update(dt)
 if not self.relayConfirmed or not self.gameStarted then return end
 self.time=self.time+dt;self.modalTime=self.modalTime+dt;self.toastTime=math.max(0,self.toastTime-dt);self.stats.updates=self.stats.updates+1
 if self.typing then self.typing:update(dt)end
 if not self.ready then if not self.loadError then local ok,err=pcall(function()self:loadNext()end);if not ok then self.loadError=tostring(err);print('LOADING_FAILURE '..self.loadError)end end;return end
 if not self.modal then E.tick(self.state,math.min(dt,.1))end
 self.tutorial:update(self.state,math.min(dt,.1),self.modal)
 if self.modal=='growth'then if not self.preview then self.preview=Previews.new(self.manifest,self.vg)end;self.preview:select(self.state,self.selected);self.preview:update(math.min(dt,.1))end
 for _,event in ipairs(self.state.events)do if event.id>self.lastEvent then self.lastEvent=event.id;self.audio:event(event)
  if not self.modal then self.typing:event(event)end
  if event.type=='story'and event.storyIndex==1 and not self.modal then self.storyIndex=1;self:show('story')end
  if event.type=='unlock'then self:toast(event.text or'身体记住了新的本领。')end
  if(event.type=='memory'or event.type=='qte-complete')and event.text then for _,m in ipairs(E.MEMORIES)do if m.text==event.text then local word;for _,v in ipairs(self.words)do if v.word==m.text then word=v end end;if not word then word={word=m.text,pinyin=m.pinyin,category=m.category,uses=0,mastery=0,source='story'};self.words[#self.words+1]=word end;word.uses=word.uses+1;word.mastery=math.min(100,word.mastery+2)end end end
 end end
 self.audio:update(self.state,dt)
 if not self.modal and self.state.phase=='rest'then self.storyIndex=math.min(4,self.state.chapter+1);self:show('story')end
 if not self.modal and self.state.phase=='ending'then self:show('ending')end
 if not self.testMode and self.time-self.saveTimer>8 then self:persist();self.saveTimer=self.time end
 if self.modal and self.worldHandle then return end
 -- Keep the same logical density as H5. Only the native presentation scales the world.
 local dpr=graphics:GetDPR();local width=self.viewportWidth or math.min(graphics.width/dpr,520);local height=self.viewportHeight or graphics.height/dpr;local controls=self.keyboardHidden and 100 or math.min(290,math.max(246,height*.30));local worldH=height-controls
 local targetH=math.max(80,math.ceil(worldH/width*192));if targetH~=self.worldCanvas.height then self.worldCanvas.height=targetH;self.renderer:resize()end
 local started=os.clock();self.renderer:render(self.state,math.min(dt,.1));self.worldHandle=Canvas.upload(self.worldCanvas,self.vg);local ms=(os.clock()-started)*1000;self.stats.worldFrames=self.stats.worldFrames+1;self.stats.totalMs=self.stats.totalMs+ms;self.stats.maxMs=math.max(self.stats.maxMs,ms)
end
-- 防剧透页沿用标准 2D 脚手架的 UI.Init → SetRoot 生命周期。
local RelayUI=require('urhox-libs/UI')
function Start()
 graphics.windowTitle='接龙防剧透';input.mouseMode=MM_FREE;input.mouseVisible=true
 RelayUI.Init({theme='default-dark',scale=RelayUI.Scale.DEFAULT})
 RelayUI.SetRoot(RelayUI.Panel{
  id='relay-gate',width='100%',height='100%',backgroundColor={13,25,28,255},pointerEvents='auto',
  children={RelayUI.SafeAreaView{
   width='100%',height='100%',nativeMenuInset=true,justifyContent='center',alignItems='center',padding=24,
   children={RelayUI.Panel{
    width='100%',maxWidth=440,padding=28,gap=18,backgroundColor={20,29,27,255},
    borderWidth=1,borderColor={91,97,83,255},borderRadius=12,
    children={
     RelayUI.Label{text='接龙防剧透',fontSize=25,fontColor={229,219,192,255},textAlign='center'},
     RelayUI.Label{text='请确定你为下一棒再进入游戏',fontSize=18,fontColor={229,219,192,255},textAlign='center',whiteSpace='normal'},
     RelayUI.Label{text='当前已遮挡全部游戏内容，并关闭游戏声音。',fontSize=14,fontColor={162,164,143,255},textAlign='center',whiteSpace='normal'},
     RelayUI.Label{text='点击确认后才把游戏放出来。',fontSize=14,fontColor={162,164,143,255},textAlign='center',whiteSpace='normal'},
     RelayUI.Button{id='relay-confirm',text='确认，我是下一棒',height=52,marginTop=8,
      backgroundColor={237,188,120,255},textColor={20,29,27,255},
      onClick=function()if not App.relayConfirmed then App.relayConfirmed=true;print('RELAY_GATE_CONFIRMED')end end},
    },
   }},
  }},
 })
 SubscribeToEvent('Update','FlameUpdate')
 print('RELAY_GATE_READY gameLoaded=false audioLoaded=false')
end
local function StartJourney()
 -- 在确认事件之后的下一帧初始化，避免确认点击穿透至游戏。
 RelayUI.Shutdown()
 graphics.windowTitle='火苗';input.mouseMode=MM_FREE;input.mouseVisible=true;GetUI():SetUseSystemClipboard(true);App.vg=assert(nvgCreate(0));nvgSetRenderOrder(App.vg,10);App.ui=UI.new(App,App.vg)
 App.typing=require('platform.typing-feedback').new(App)
 SubscribeToEvent('KeyDown','FlameKeyDown');SubscribeToEvent('MouseButtonDown','FlameMouseDown');SubscribeToEvent('TouchBegin','FlameTouchBegin');SubscribeToEvent('InputFocus','FlameFocus');SubscribeToEvent(App.vg,'NanoVGRender','FlameRender')
 App.gameStarted=true
end
function FlameUpdate(_,eventData)
 if not App.relayConfirmed then return end
 if not App.gameStarted then StartJourney();return end
 local dt=eventData['TimeStep']:GetFloat();App:update(dt);Canvas.flushGPU()
end
function FlameRender()
 if not App.gameStarted then return end
 App.stats.renders=App.stats.renders+1;local dpr=graphics:GetDPR();local w,h=graphics.width/dpr,graphics.height/dpr;nvgBeginFrame(App.vg,w,h,dpr);App.ui:render(w,h,0);nvgEndFrame(App.vg)
end
function FlameKeyDown(_,eventData)
 if not App.gameStarted then return end
 local key=eventData['Key']:GetInt();local repeatKey=eventData['Repeat']and eventData['Repeat']:GetBool();if repeatKey then return end
 if key==KEY_ESCAPE then if App.modal then App:back()elseif App.ready then App:show('pause')end;return end
 if key==KEY_RETURN and App.modal=='title'then App:begin();return elseif key==KEY_RETURN and App.modal=='story'then App:continueStory();return end
 if key==KEY_RETURN and App.loadError then App:retryLoad();return end
 if key==KEY_TAB and App.modal then App.focusIndex=App.keyboardFocus and((App.focusIndex or 0)%math.max(1,#App.ui.hits))+1 or 1;App.keyboardFocus=true;return end
 if key==KEY_RETURN and App.modal then local hit=App.ui.hits[App.focusIndex or 1];if hit then hit.fn()end;return end
 if key==KEY_SPACE then App:stroke(' ');return elseif key==KEY_BACKSPACE then App:stroke('Backspace');return end
 for i=1,26 do if key==_G['KEY_'..string.char(64+i)]then App:stroke(string.char(96+i));return end end
 for i=0,9 do if key==_G['KEY_'..i]then App:stroke(tostring(i));return end end
 if key==KEY_COMMA then App:stroke(',')elseif key==KEY_PERIOD then App:stroke('.')end
end
function FlameMouseDown(_,eventData)if not App.gameStarted then return end;if eventData['Button']:GetInt()~=MOUSEB_LEFT then return end;local p=input:GetMousePosition();local dpr=graphics:GetDPR();App.ui:tap(p.x/dpr-(App.offset or 0),p.y/dpr)end
function FlameTouchBegin(_,eventData)if not App.gameStarted then return end;local dpr=graphics:GetDPR();App.ui:tap(eventData['X']:GetInt()/dpr-(App.offset or 0),eventData['Y']:GetInt()/dpr)end
function FlameFocus(_,eventData)if eventData['Focus']and not eventData['Focus']:GetBool()and App.ready and not App.modal then App:show('pause')end end
function Stop()if not App.gameStarted then RelayUI.Shutdown();return end;App:persist();App:releasePreviews();if App.renderer then Canvas.disposeRenderer(App.renderer,App.vg)end;if App.worldCanvas then Canvas.dispose(App.worldCanvas,App.vg)end;if App.audio then App.audio:dispose()end;if App.ui then App.ui:dispose()end;if App.vg then nvgDelete(App.vg)end end
return App
