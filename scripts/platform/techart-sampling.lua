-- Sampling conventions shared by the translated Nocturnal passes.
-- Image coordinates are top-down; the fluid alone requests flipped Y.
local C = require('platform.canvas')
local M = {}
local floor, min, max = math.floor, math.min, math.max
function M.clamp(v, lo, hi) return max(lo or 0, min(hi or 1, v)) end
function M.fract(v) return v - floor(v) end
function M.canvas(w,h) local c=C.new(w,h);c:ensure();return c end
local decoded=setmetatable({},{__mode='k'})
function M.texture(image, linear, repeatX, repeatY, flipY,dynamic)
 local data=not dynamic and decoded[image]or nil
 if not data then data={r={},g={},b={},a={}};for i=1,image.width*image.height do local r,g,b,a=C.rgba(image.pixels[i]or 0);data.r[i]=r/255;data.g[i]=g/255;data.b[i]=b/255;data.a[i]=a/255 end;if not dynamic then decoded[image]=data end end
 return {image=image,width=image.width,height=image.height,linear=linear,repeatX=repeatX,repeatY=repeatY,flipY=flipY,r=data.r,g=data.g,b=data.b,a=data.a}
end
local function index(t,x,y)
 if t.repeatX then x=x%t.width else x=max(0,min(t.width-1,x)) end
 if t.repeatY then y=y%t.height else y=max(0,min(t.height-1,y)) end
 if t.flipY then y=t.height-1-y end
 return y*t.width+x+1
end
function M.sample(t,u,v)
 if not t.linear then local i=index(t,floor(u*t.width),floor(v*t.height));return t.r[i],t.g[i],t.b[i],t.a[i]end
 local x,y=u*t.width-.5,v*t.height-.5;local ix,iy=floor(x),floor(y);local fx,fy=x-ix,y-iy
 local i0,i1,i2,i3=index(t,ix,iy),index(t,ix+1,iy),index(t,ix,iy+1),index(t,ix+1,iy+1)
 local p,q,s,z=(1-fx)*(1-fy),fx*(1-fy),(1-fx)*fy,fx*fy
 local r,g,b,a=t.r,t.g,t.b,t.a
 return r[i0]*p+r[i1]*q+r[i2]*s+r[i3]*z,g[i0]*p+g[i1]*q+g[i2]*s+g[i3]*z,b[i0]*p+b[i1]*q+b[i2]*s+b[i3]*z,a[i0]*p+a[i1]*q+a[i2]*s+a[i3]*z
end
function M.red(t,u,v)
 if not t.linear then return t.r[index(t,floor(u*t.width),floor(v*t.height))]end
 local x,y=u*t.width-.5,v*t.height-.5;local ix,iy=floor(x),floor(y);local fx,fy=x-ix,y-iy
 local r=t.r;local a,b,c,d=r[index(t,ix,iy)],r[index(t,ix+1,iy)],r[index(t,ix,iy+1)],r[index(t,ix+1,iy+1)]
 return(a+(b-a)*fx)*(1-fy)+(c+(d-c)*fx)*fy
end
function M.palette(x)
 if x<.55 then local v=x/.55;return .59+(.41)*v,.10+.30*v,.018+.037*v end
 local v=M.clamp((x-.55)/.45);return 1,.4+.52*v,.055+.595*v
end
-- JS Math.imul semantics, including low bits beyond double's 53-bit product range.
---@type table<string,any> The runtime exposes either bit32 or the LuaJIT bit API.
local bitlib = bit32 or bit or require('bit')
local bxor,rshift,tobit=bitlib.bxor,bitlib.rshift,bitlib.tobit
local function imul(a,b)
 local al,bl=a%65536,b%65536
 local n=al*bl+((floor(a/65536)*bl+al*floor(b/65536))%65536)*65536
 return tobit and tobit(n) or n%4294967296
end
M.imul=imul
function M.random(seed)
 local x=(seed<0 and math.ceil(seed)or floor(seed))%4294967296;x=imul(bxor(x,rshift(x,16)),73244475);x=imul(bxor(x,rshift(x,16)),73244475)
 return bxor(x,rshift(x,16))%4294967296/4294967296
end
function M.noise(x,y,seed)
 local n=bxor(imul(x,374761393),imul(y,668265263),seed)
 n=imul(bxor(n,rshift(n,13)),1274126177)
 return bxor(n,rshift(n,16))%4294967296/4294967295
end
function M.smooth(a,b,x)local t=M.clamp((x-a)/(b-a));return t*t*(3-2*t)end
return M
