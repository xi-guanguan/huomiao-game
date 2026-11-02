shader_type compute;
workgroup_size(8,8,1);
uniform sampler2D source_map : filter_nearest, repeat_disable;
writeonly buffer vec4 result_data[];
void compute(){uvec2 p=GLOBAL_INVOCATION_ID.xy;result_data[p.x+p.y*DISPATCH_SIZE.x]=texelFetch(source_map,ivec2(p),0);}
