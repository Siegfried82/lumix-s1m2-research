@group(0) @binding(0) var<storage,read> s4:array<f32>;
@group(0) @binding(1) var<storage,read> s6:array<f32>;
@group(0) @binding(2) var<storage,read> dec:array<f32>;
@group(0) @binding(3) var<storage,read> black:array<f32>;
@group(0) @binding(4) var<storage,read_write> base:array<f32>;
@group(0) @binding(5) var<storage,read_write> band:array<f32>;
@group(0) @binding(6) var<storage,read_write> budget:array<f32>;
@group(0) @binding(7) var<storage,read_write> comp:array<f32>;
struct Box{xy:vec2<u32>,size:vec2<u32>,delta:vec2<u32>,pad:vec2<u32>};
@group(0) @binding(8) var<uniform> box:Box;
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){
let i=g.x+g.y*4194304u;let count=box.size.x*box.size.y;if(i>=7u*count){return;}
let f=i/count;let p=i%count;let x=p%box.size.x;let y=p/box.size.x;
let src=(y+box.delta.y)*