@group(0) @binding(0) var<storage,read> mask:array<f32>;
@group(0) @binding(1) var<storage,read> evidence:array<f32>;
@group(0) @binding(2) var<storage,read_write> seed:array<u32>;
@group(0) @binding(3) var<storage,read_write> support:array<u32>;
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) gid:vec3<u32>){let i=gid.x+gid.y*4194304u;if(i>=