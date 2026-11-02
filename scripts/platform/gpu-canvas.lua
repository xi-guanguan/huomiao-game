-- Canvas draw commands rendered by the official NanoVG backend. Pixel material
-- passes can explicitly materialize the same commands through the scalar backend.
local G={canvases={}};local C,original
local function copy(t)local r={};for k,v in pairs(t)do r[k]=v end;return r end
local function polygons(t)local r={};for i,p in ipairs(t)do local q={closed=p.closed};for j,v in ipairs(p)do q[j]={v[1],v[2]}end;r[i]=q end;return r end
local function color(p)local r,g,b,a=C.rgba(C.parse(p));return nvgRGBA(r,g,b,a)end
function G.enable(canvas)
 if not canvas.gpu then canvas.gpu={commands={},images={},uploads={},handles={},generation=0};G.canvases[#G.canvases+1]=canvas end
 return canvas
end
local function record(ctx,name,args)
 local canvas=ctx.canvas;canvas:ensure();local gpu=canvas.gpu
 if gpu.width~=canvas.width or gpu.height~=canvas.height then gpu.commands={};gpu.width=canvas.width;gpu.height=canvas.height end
 local t=ctx.t
 if t[1]==1 and t[2]==0 and t[3]==0 and t[4]==1 and t[5]==0 and t[6]==0 and #ctx.clips==0 then
  if name=='clearRect'and args[1]==0 and args[2]==0 and args[3]>=canvas.width and args[4]>=canvas.height then gpu.commands={};gpu.generation=gpu.generation+1;return end
  if name=='fillRect'and args[1]==0 and args[2]==0 and args[3]>=canvas.width and args[4]>=canvas.height and ctx.globalAlpha==1 and ctx.globalCompositeOperation=='source-over'and type(ctx.fillStyle)~='table'and(C.parse(ctx.fillStyle) >> 24)==255 then gpu.commands={}end
 end
 if name=='drawImage'then local source=args[1];source:ensure();if not source.gpu then args[1]={width=source.width,height=source.height,pixels=source.pixels,resourcePath=source.resourcePath,nativeTexture=source.nativeTexture}end end
 gpu.commands[#gpu.commands+1]={name=name,args=args,t=copy(t),path=(name=='fill'or name=='stroke')and polygons(ctx.path)or{},clips=polygons(ctx.clips),alpha=ctx.globalAlpha,blend=ctx.globalCompositeOperation,fill=ctx.fillStyle,stroke=ctx.strokeStyle,line=ctx.lineWidth}
 gpu.generation=gpu.generation+1
end
local function target(canvas)
 local gpu=canvas.gpu
 if gpu.targetW~=canvas.width or gpu.targetH~=canvas.height then
  for vg,handle in pairs(gpu.handles)do nvgDeleteVideo(vg,handle)end;gpu.handles={}
  if gpu.vg then for _,handle in pairs(gpu.images)do nvgDeleteImage(gpu.vg,handle)end;for _,upload in pairs(gpu.uploads)do original.dispose(upload,gpu.vg)end;for _,other in ipairs(G.canvases)do if other.gpu then other.gpu.handles[gpu.vg]=nil end end;nvgDelete(gpu.vg)end
  gpu.images={};gpu.uploads={}
  gpu.texture=Texture2D:new();gpu.texture:SetNumLevels(1);assert(gpu.texture:SetSize(canvas.width,canvas.height,Graphics:GetRGBAFormat(),TEXTURE_RENDERTARGET),'Canvas render target unavailable');gpu.texture:SetFilterMode(FILTER_NEAREST)
  gpu.vg=assert(nvgCreate(0));nvgSetRenderTarget(gpu.vg,gpu.texture);nvgSetRenderOrder(gpu.vg,gpu.order or -100);gpu.targetW=canvas.width;gpu.targetH=canvas.height;gpu.flushed=nil
 end
 return gpu
end
function G.handle(canvas,vg)
 local gpu=target(canvas);if not gpu.handles[vg]then gpu.handles[vg]=nvgCreateVideo(vg,gpu.texture);assert(gpu.handles[vg]>0)end;return gpu.handles[vg]
end
local blends={['source-over']='NVG_SOURCE_OVER',['source-in']='NVG_SOURCE_IN',['source-atop']='NVG_SOURCE_ATOP',['destination-in']='NVG_DESTINATION_IN',copy='NVG_COPY',lighter='NVG_LIGHTER'}
local function blend(vg,mode)
 if mode=='screen'then nvgGlobalCompositeBlendFunc(vg,NVG_ONE,NVG_ONE_MINUS_SRC_COLOR)
 elseif mode=='multiply'then nvgGlobalCompositeBlendFunc(vg,NVG_DST_COLOR,NVG_ONE_MINUS_SRC_ALPHA)
 else assert(blends[mode],'Unsupported canvas blend '..mode);nvgGlobalCompositeOperation(vg,_G[blends[mode]])end
end
local function paint(vg,style,stroke)
 if type(style)~='table'then if stroke then nvgStrokeColor(vg,color(style))else nvgFillColor(vg,color(style))end;return end
 local stops=style.stops;assert(#stops==2,'Native gradient requires its authored two stops')
 local p;if style.kind=='linear'then p=nvgLinearGradient(vg,style.x0,style.y0,style.x1,style.y1,color(stops[1][2]),color(stops[2][2]))else p=nvgRadialGradient(vg,style.x1,style.y1,style.r0,style.r1,color(stops[1][2]),color(stops[2][2]))end
 if stroke then nvgStrokePaint(vg,p)else nvgFillPaint(vg,p)end
end
local function path(vg,polys)
 nvgBeginPath(vg);for _,poly in ipairs(polys)do for i,p in ipairs(poly)do if i==1 then nvgMoveTo(vg,p[1],p[2])else nvgLineTo(vg,p[1],p[2])end end;if poly.closed then nvgClosePath(vg)end end
end
function G.flush(canvas,visiting)
 local gpu=target(canvas);if gpu.flushed==gpu.generation then return gpu.depth or 0 end
 visiting=visiting or{};assert(not visiting[canvas],'Cyclic canvas dependency');visiting[canvas]=true
 local depth=0
 for _,cmd in ipairs(gpu.commands)do if cmd.name=='drawImage'and cmd.args[1].gpu then depth=math.max(depth,G.flush(cmd.args[1],visiting)+1)end end
 visiting[canvas]=nil;gpu.depth=depth;nvgSetRenderOrder(gpu.vg,-100+depth)
 local vg=gpu.vg;nvgBeginFrame(vg,canvas.width,canvas.height,1)
 nvgGlobalCompositeOperation(vg,NVG_COPY);nvgBeginPath(vg);nvgRect(vg,0,0,canvas.width,canvas.height);nvgFillColor(vg,nvgRGBA(0,0,0,0));nvgFill(vg)
 for index,cmd in ipairs(gpu.commands)do
  nvgSave(vg);nvgResetTransform(vg);nvgGlobalAlpha(vg,cmd.alpha);blend(vg,cmd.blend)
  for _,poly in ipairs(cmd.clips)do local x0,y0,x1,y1=1e9,1e9,-1e9,-1e9;for _,p in ipairs(poly)do x0=math.min(x0,p[1]);y0=math.min(y0,p[2]);x1=math.max(x1,p[1]);y1=math.max(y1,p[2])end;nvgIntersectScissor(vg,x0,y0,x1-x0,y1-y0)end
  local args,t=cmd.args,cmd.t
  if cmd.name=='fill'or cmd.name=='stroke'then
   path(vg,cmd.path)
   if cmd.name=='fill'then paint(vg,cmd.fill);nvgFill(vg)else paint(vg,cmd.stroke,true);nvgStrokeWidth(vg,cmd.line*math.sqrt(math.abs(t[1]*t[4]-t[2]*t[3])));nvgStroke(vg)end
  else
   nvgTransform(vg,t[1],t[2],t[3],t[4],t[5],t[6])
   if cmd.name=='fillRect'then paint(vg,cmd.fill);nvgBeginPath(vg);nvgRect(vg,args[1],args[2],args[3],args[4]);nvgFill(vg)
   elseif cmd.name=='clearRect'then nvgGlobalCompositeOperation(vg,NVG_COPY);nvgFillColor(vg,nvgRGBA(0,0,0,0));nvgBeginPath(vg);nvgRect(vg,args[1],args[2],args[3],args[4]);nvgFill(vg)
   elseif cmd.name=='drawImage'then
    local source=args[1];local handle
    if source.gpu then handle=G.handle(source,vg)
    elseif source.nativeTexture then local item=gpu.uploads[index];if not item or item.nativeTexture~=source.nativeTexture then if item then original.dispose(item,vg)end;item={nativeTexture=source.nativeTexture,handle=nvgCreateVideo(vg,source.nativeTexture)};gpu.uploads[index]=item end;handle=item.handle
    elseif source.resourcePath then handle=gpu.images[source.resourcePath];if not handle then handle=nvgCreateImage(vg,source.resourcePath,NVG_IMAGE_NEAREST);assert(handle>0);gpu.images[source.resourcePath]=handle end
    else
     local upload=gpu.uploads[index];if upload and upload.nativeTexture then original.dispose(upload,vg);upload=nil end;if not upload then upload=C.new(source.width,source.height);gpu.uploads[index]=upload end
     if upload.sourcePixels~=source.pixels or upload.width~=source.width or upload.height~=source.height then upload.width=source.width;upload.height=source.height;upload:ensure();upload.pixels=source.pixels;upload.sourcePixels=source.pixels;upload.handle=original.upload(upload,vg)end;handle=upload.handle
    end
    local sx,sy,sw,sh,dx,dy,dw,dh=0,0,source.width,source.height,0,0,source.width,source.height
    if #args==3 then dx,dy=args[2],args[3]elseif #args==5 then dx,dy,dw,dh=table.unpack(args,2)else sx,sy,sw,sh,dx,dy,dw,dh=table.unpack(args,2)end
    if dw~=0 and dh~=0 then nvgIntersectScissor(vg,dx,dy,dw,dh);nvgBeginPath(vg);nvgRect(vg,dx,dy,dw,dh);nvgFillPaint(vg,nvgImagePattern(vg,dx-sx*dw/sw,dy-sy*dh/sh,source.width*dw/sw,source.height*dh/sh,0,handle,1));nvgFill(vg)end
   else error('Unsupported GPU canvas operation '..cmd.name)end
  end
  nvgRestore(vg)
 end
 nvgEndFrame(vg);gpu.flushed=gpu.generation;return depth
end
function G.flushAll()for _,canvas in ipairs(G.canvases)do if canvas.gpu and #canvas.gpu.commands>0 then G.flush(canvas)end end end
function G.materialize(canvas)
 local gpu=canvas.gpu;if not gpu or gpu.materialized==gpu.generation then return end
 local ctx=canvas:getContext();local saved={t=ctx.t,path=ctx.path,clips=ctx.clips,alpha=ctx.globalAlpha,blend=ctx.globalCompositeOperation,fill=ctx.fillStyle,stroke=ctx.strokeStyle,line=ctx.lineWidth}
 canvas.gpu=nil;canvas.pixels={}
 for _,cmd in ipairs(gpu.commands)do ctx.t=cmd.t;ctx.path=cmd.path;ctx.clips=cmd.clips;ctx.globalAlpha=cmd.alpha;ctx.globalCompositeOperation=cmd.blend;ctx.fillStyle=cmd.fill;ctx.strokeStyle=cmd.stroke;ctx.lineWidth=cmd.line;ctx[cmd.name](ctx,table.unpack(cmd.args))end
 canvas.gpu=gpu;gpu.materialized=gpu.generation;ctx.t=saved.t;ctx.path=saved.path;ctx.clips=saved.clips;ctx.globalAlpha=saved.alpha;ctx.globalCompositeOperation=saved.blend;ctx.fillStyle=saved.fill;ctx.strokeStyle=saved.stroke;ctx.lineWidth=saved.line
end
function G.region(canvas,x,y,w,h,out)
 out=out or C.new(w,h);out.width=w;out.height=h;out:ensure();out.pixels={};local ctx=out:getContext();ctx:reset()
 if not canvas.gpu then ctx:drawImage(canvas,-x,-y);return out end
 local commands=canvas.gpu.commands;local prefix=0
 for i,cmd in ipairs(commands)do if cmd.name=='drawImage'and not cmd.args[1].resourcePath then break end;prefix=i end
 local function equal(a,b)
  if a==b then return true end;if type(a)~='table'or type(b)~='table'then return false end
  for k,v in pairs(a)do if k~='pixels'and not equal(v,b[k])then return false end end
  for k in pairs(b)do if k~='pixels'and a[k]==nil then return false end end;return true
 end
 local cached=out.regionCache;local reuse=cached and cached.x==x and cached.y==y and cached.w==w and cached.h==h and cached.prefix==prefix
 if reuse then for i=1,prefix do if not equal(cached.commands[i],commands[i])then reuse=false;break end end end
 if reuse then out.pixels=copy(cached.pixels);if prefix==#commands then return out end end
 local function shifted(polys)local r=polygons(polys);for _,poly in ipairs(r)do for _,p in ipairs(poly)do p[1]=p[1]-x;p[2]=p[2]-y end end;return r end
 local function style(value)if type(value)~='table'or not value.inv then return value end;local v=copy(value);v.inv=copy(value.inv);v.inv[5]=v.inv[5]+v.inv[1]*x+v.inv[3]*y;v.inv[6]=v.inv[6]+v.inv[2]*x+v.inv[4]*y;return v end
 for index,cmd in ipairs(commands)do
  if not reuse or index>prefix then
  ctx.t=copy(cmd.t);ctx.t[5]=ctx.t[5]-x;ctx.t[6]=ctx.t[6]-y;ctx.path=shifted(cmd.path);ctx.clips=shifted(cmd.clips);ctx.globalAlpha=cmd.alpha;ctx.globalCompositeOperation=cmd.blend;ctx.fillStyle=style(cmd.fill);ctx.strokeStyle=style(cmd.stroke);ctx.lineWidth=cmd.line
  if cmd.name=='drawImage'then assert(not cmd.args[1].nativeTexture,'Pixel readback of compute output was not requested')end
  local a,t=cmd.args,ctx.t;local image=a[1]
  if cmd.name=='drawImage'and #a==3 and not image.gpu and not image.nativeTexture and not image.resourcePath and cmd.blend=='copy'and cmd.alpha==1 and #cmd.clips==0 and t[1]==1 and t[2]==0 and t[3]==0 and t[4]==1 and(a[2]+t[5])%1==0 and(a[3]+t[6])%1==0 then
   -- Exact integer COPY, used by the live scorch patch. Avoid resampling each
   -- pixel through the general affine Canvas path during fire background reads.
   local dx,dy=a[2]+t[5],a[3]+t[6];local pixels=out.pixels
   for yy=math.max(0,-dy),math.min(image.height-1,h-1-dy)do local src=yy*image.width;local dst=(yy+dy)*w+dx;for xx=math.max(0,-dx),math.min(image.width-1,w-1-dx)do pixels[dst+xx+1]=image.pixels[src+xx+1]or 0 end end
  else ctx[cmd.name](ctx,table.unpack(a))end
  end
  if not reuse and index==prefix then local entries={};for i=1,prefix do entries[i]=commands[i]end;out.regionCache={x=x,y=y,w=w,h=h,prefix=prefix,commands=entries,pixels=copy(out.pixels)}end
 end
 ctx:reset();return out
end
function G.dispose(canvas)
 local gpu=canvas.gpu;if not gpu then return end
 for vg,handle in pairs(gpu.handles)do nvgDeleteVideo(vg,handle)end
 if gpu.vg then for _,handle in pairs(gpu.images)do nvgDeleteImage(gpu.vg,handle)end;for _,upload in pairs(gpu.uploads)do original.dispose(upload,gpu.vg)end;for _,other in ipairs(G.canvases)do if other.gpu then other.gpu.handles[gpu.vg]=nil end end;nvgDelete(gpu.vg)end
 canvas.gpu=nil;for i=#G.canvases,1,-1 do if G.canvases[i]==canvas then table.remove(G.canvases,i)end end
end
function G.install(canvasModule)
 C=canvasModule;original={upload=C.upload,dispose=C.dispose};local proto=getmetatable(C.new(1,1):getContext())
 for _,name in ipairs({'fillRect','drawImage','fill','stroke','clearRect','putImageData'})do
  local fn=proto[name];original[name]=fn
  proto[name]=function(self,...)
   if self.canvas.gpu then return record(self,name,{...})end
   if name=='drawImage'then local image=(...);if image.gpu then G.materialize(image)end end
   return fn(self,...)
  end
 end
 C.enableGPU=G.enable;C.flushGPU=G.flushAll;C.materialize=G.materialize;C.region=G.region
 C.enableRenderer=function(renderer,stage)
  G.enable(stage);G.enable(renderer.back);G.enable(renderer.surfaceMask);G.enable(renderer.actorSurface)
  local atmosphere=renderer.atmosphere;local fn=atmosphere.lightActor;renderer.nativeLights={}
  atmosphere.lightActor=function(self,source,p)
   local key=p.enemy and'enemy'or'hero';local lit=renderer.nativeLights[key]
   if not lit then lit=G.enable(C.new(source.width,source.height));renderer.nativeLights[key]=lit end
   self.lit=lit;self.light=lit:getContext();return fn(self,source,p)
  end
 end
 C.disposeRenderer=function(renderer,vg)renderer:dispose();for _,v in pairs(renderer.nativeLights or{})do C.dispose(v,vg)end;C.dispose(renderer.actorSurface,vg);C.dispose(renderer.back,vg);C.dispose(renderer.surfaceMask,vg)end
 C.upload=function(canvas,vg)if canvas.gpu then return G.handle(canvas,vg)end;return original.upload(canvas,vg)end
 C.dispose=function(canvas,vg)if canvas.gpu then G.dispose(canvas)else original.dispose(canvas,vg)end end
end
return G
