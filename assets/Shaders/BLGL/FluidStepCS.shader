// Single authored closed container. Equations follow platform/nocturnal-fluid.lua
// and the H5 Nocturnal/Fluxy passes; fields retain all RGBA channels in RGBA16F.
shader_type compute;
workgroup_size(8,8,1);
uniform int pass_id=0;
uniform float dt=0.01666667;
uniform float clock=0.0;
uniform vec4 brush=vec4(0.5,0.1,0.1,0.1);
uniform vec4 weights=vec4(0.1);
uniform vec2 impulse=vec2(0.0);
uniform float erase=0.0;
uniform float initial_density=0.0;
uniform sampler2D state_map : filter_nearest, repeat_disable;
uniform sampler2D velocity_map : filter_nearest, repeat_disable;
uniform sampler2D aux_map : filter_nearest, repeat_disable;
uniform sampler2D detail_map : filter_linear, repeat_enable;
uniform sampler2D flow_map : filter_linear, repeat_enable;
uniform sampler2D splat_map : filter_linear, repeat_disable;
uniform writeonly image2D result_state : format_rgba16f;
uniform writeonly image2D result_velocity : format_rgba16f;
uniform writeonly image2D result_aux : format_rgba16f;
vec4 st(ivec2 p){return texelFetch(state_map,clamp(p,ivec2(0),ivec2(DISPATCH_SIZE.xy)-1),0);}
vec4 vel(ivec2 p){return texelFetch(velocity_map,clamp(p,ivec2(0),ivec2(DISPATCH_SIZE.xy)-1),0);}
vec4 bordered(sampler2D tex,ivec2 p){
 if(p.x<0||p.y<0||p.x>=int(DISPATCH_SIZE.x)||p.y>=int(DISPATCH_SIZE.y))return vec4(0.0);
 return texelFetch(tex,p,0);
}
vec4 advected(sampler2D tex,vec2 p){
 ivec2 q=ivec2(floor(p));vec2 f=fract(p);
 return mix(mix(bordered(tex,q),bordered(tex,q+ivec2(1,0)),f.x),mix(bordered(tex,q+ivec2(0,1)),bordered(tex,q+ivec2(1,1)),f.x),f.y);
}
vec4 splatAt(vec2 uv){return textureLod(splat_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 detailAt(vec2 uv){return textureLod(detail_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 flowAt(vec2 uv){return textureLod(flow_map,vec2(uv.x,1.0-uv.y),0.0);}
void compute(){
 ivec2 p=ivec2(GLOBAL_INVOCATION_ID.xy),size=ivec2(DISPATCH_SIZE.xy);
 vec2 uv=(vec2(p)+vec2(.5))/vec2(size);
 vec4 s=vec4(0),v=vec4(0),a=vec4(0);
 if(pass_id==0){s=vec4(0,.6,.66,initial_density);}
 else{
  s=st(p);v=vel(p);a=texelFetch(aux_map,p,0);
  if(pass_id==1){
   vec2 q=(uv-brush.xy)/(brush.zw*2.0)+vec2(.5);
   if(q.x>=0.0&&q.x<=1.0&&q.y>=0.0&&q.y<=1.0){
    vec4 stamp=splatAt(q);
    if(erase>.5)s*=1.0-stamp.a*clamp(weights.a,0.0,1.0);
    else{float n=.15*(detailAt((q+vec2(clock/20.0*.2))*2.0).r-1.0)+1.0;s+=stamp*weights*n;}
    if(dot(impulse,impulse)>0.0){
     vec2 t=1.0/vec2(textureSize(splat_map,0));
     float l=splatAt(q-vec2(t.x,0)).a,r=splatAt(q+vec2(t.x,0)).a;
     float d=splatAt(q-vec2(0,t.y)).a,u=splatAt(q+vec2(0,t.y)).a;
     v.xy=mix(v.xy,stamp.a*impulse-vec2(r-l,u-d)*.5,stamp.a);
    }
   }
  }else if(pass_id==2){
   vec4 f=flowAt(uv);if(dot(f.rg,f.rg)>0.0)v.xy=(v.xy+.2*dt*((f.rg*2.0-1.0)*.11-v.xy))*f.a;
  }else if(pass_id==3){
   vec2 q=vec2(p)-v.xy*dt*vec2(size);s=advected(state_map,q);v=advected(velocity_map,q);a=s;
  }else if(pass_id==4){
   float red=s.r*dt;s.rgb=clamp(s.rgb-vec3(red),vec3(0),vec3(1));s.a=clamp(s.a-dt*pow(1.0-s.a,2.0)*.92,0.0,1.0);
   v.b=.5*(vel(p+ivec2(1,0)).g-vel(p-ivec2(1,0)).g+vel(p+ivec2(0,1)).r-vel(p-ivec2(0,1)).r);
  }else if(pass_id==5){
   vec2 g=.5*vec2(abs(vel(p-ivec2(0,1)).b)-abs(vel(p+ivec2(0,1)).b),abs(vel(p+ivec2(1,0)).b)-abs(vel(p-ivec2(1,0)).b));
   float len=length(g),force=len>.001?v.b*8.0/len:0.0;
   v.xy=v.xy*exp(-.2*dt)+(g*force+vec2(0,.32*a.a))*dt;
  }else if(pass_id==6){
   float l=p.x>0?vel(p-ivec2(1,0)).r:0.0,r=p.x<size.x-1?vel(p+ivec2(1,0)).r:0.0;
   float d=p.y>0?vel(p-ivec2(0,1)).g:0.0,u=p.y<size.y-1?vel(p+ivec2(0,1)).g:0.0;
   v.b=-.5*(r-l+u-d);v.a=v.b;
  }else if(pass_id==7||pass_id==8){
   ivec2 axis=pass_id==7?ivec2(1,0):ivec2(0,1);
   float sum=v.a*-.578437209;
   sum+=-.36519596*(vel(p-axis).a+vel(p+axis).a);
   sum+=-.23187989*(vel(p-axis*2).a+vel(p+axis*2).a);
   sum+=-.145295888*(vel(p-axis*3).a+vel(p+axis*3).a);
   sum+=-.0881648734*(vel(p-axis*4).a+vel(p+axis*4).a);
   sum+=-.0518487282*(vel(p-axis*5).a+vel(p+axis*5).a);
   sum+=-.0290646255*(vel(p-axis*6).a+vel(p+axis*6).a);
   if(pass_id==8)a=v;v.a=sum;
  }else if(pass_id==9){
   v.xy-=.5*.8*vec2(vel(p+ivec2(1,0)).a-vel(p-ivec2(1,0)).a,vel(p+ivec2(0,1)).a-vel(p-ivec2(0,1)).a);v.a=a.a;
  }
 }
 imageStore(result_state,p,s);imageStore(result_velocity,p,v);imageStore(result_aux,p,a);
}
