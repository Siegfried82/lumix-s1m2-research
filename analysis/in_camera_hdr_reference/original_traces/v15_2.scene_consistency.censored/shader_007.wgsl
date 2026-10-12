@group(0) @binding(0) var<storage,read> labels:array<u32>;
@group(0) @binding(1) var<storage,read> decision:array<f32>;
@group(0) @binding(2) var<storage,read_write> mask:array<f32>;
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){let p=g.x+g.y*4194304u;if(p>=