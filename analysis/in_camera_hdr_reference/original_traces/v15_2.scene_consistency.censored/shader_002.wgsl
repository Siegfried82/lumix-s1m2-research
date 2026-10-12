@group(0) @binding(0) var<storage,read> labels:array<u32>;
@group(0) @binding(1) var<storage,read> base:array<f32>;
@group(0) @binding(2) var<storage,read> field:array<f32>;
@group(0) @binding(3) var<storage,read_write> stats:array<atomic<u32>>;
fn add64(j:u32,v:u32){let old=atomicAdd(&stats[j],v);if(old>0xffffffffu-v){atomicAdd(&stats[j+1u],1u);}}
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){let p=g.x+g.y*4194304u;if(p>=