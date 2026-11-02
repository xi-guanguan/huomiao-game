shader_type compute;
workgroup_size(8,8,1);
uniform sampler2D state_map : filter_nearest, repeat_disable;
uniform sampler2D velocity_map : filter_nearest, repeat_disable;
uniform sampler2D detail_map : filter_linear, repeat_enable;
uniform sampler2D flow_map : filter_linear, repeat_enable;
uniform sampler2D gradient_map : filter_linear, repeat_disable;
uniform sampler2D fire_map : filter_linear, repeat_disable;
uniform sampler2D background_map : filter_linear, repeat_disable;
uniform float clock=0.0;
uniform float distortion=1.0;
uniform writeonly image2D result : format_rgba8;
vec4 gradientAt(vec2 uv){return textureLod(gradient_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 detailAt(vec2 uv){return textureLod(detail_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 flowAt(vec2 uv){return textureLod(flow_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 fireAt(vec2 uv){return textureLod(fire_map,vec2(uv.x,1.0-uv.y),0.0);}
vec4 backgroundAt(vec2 uv){return textureLod(background_map,vec2(uv.x,1.0-uv.y),0.0);}
void compute(){
 ivec2 p=ivec2(GLOBAL_INVOCATION_ID.xy),size=ivec2(DISPATCH_SIZE.xy);vec2 uv=(vec2(p)+vec2(.5))/vec2(size);
 vec4 s=texelFetch(state_map,p,0),v=texelFetch(velocity_map,p,0);
 float t0=fract(clock),t1=fract(clock+.5),blend=abs(t0*2.0-1.0);
 float n0=detailAt(uv*2.0-v.xy*t0*1.3).r,n1=detailAt(uv*2.0-v.xy*t1*1.3).r;
 vec4 gradient=gradientAt(vec2(s.a*mix(n0,n1,blend),.5));vec4 c=s*gradient;
 c.rgb+=v.a*.22*vec3(.025,.018,.015);c.rgb*=c.a;
 vec2 edge=max(vec2(0),(abs(uv-vec2(.5))*2.0-vec2(.88))/.12);float falloff=max(0.0,1.0-length(edge));
 c.a*=clamp(2.0-c.a,0.0,1.0)*falloff;c.rgb=max(vec3(0),c.rgb*falloff);float alpha=c.a*.87;
 vec4 resultColor=vec4(0);
 if(alpha>=.1){
  c.rgb+=vec3(.05);
  if(distortion>.5){
   float flow=flowAt(uv+vec2(clock/20.0*1.1,clock/20.0*.9)).r;
   float offset=((flow*2.0-1.0)*.18*.005+v.x*.18*.15)*c.a;
   vec3 bg=backgroundAt(uv+vec2(offset)).rgb;
   vec3 bright=pow(bg+vec3(.23),vec3(5.0))*.9,cr=c.rgb*vec3(.29,.12,.055);
   vec3 m=vec3(1)-pow(mix(cr,s.rgb,.8),vec3(2));float norm=dot(m,m),factor=max(norm*sqrt(norm),1.0-alpha);
   vec3 x=max(vec3(factor)*bright,cr)*vec3(.72,.46,.28);x=mix(x,cr*cr,min(s.a,.2));
   float fire=clamp(s.a*s.r,0.0,1.0);c.rgb=mix(x,fireAt(vec2(fire,.5)).rgb*1.65,fire);
  }
  resultColor=vec4(clamp(c.rgb,vec3(0),vec3(1)),clamp(alpha,0.0,1.0));
 }
 imageStore(result,ivec2(p.x,size.y-1-p.y),resultColor);
}
