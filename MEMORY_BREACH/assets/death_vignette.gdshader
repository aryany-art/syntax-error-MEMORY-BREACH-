shader_type canvas_item;
uniform float strength : hint_range(0.0,1.0) = 0.0;
void fragment(){
    vec2 p=UV*2.0-1.0;
    float edge=smoothstep(0.1,1.2,length(p));
    float pulse=0.96+0.04*sin(TIME*3.0);
    COLOR=vec4(0.62,0.005,0.025,strength*(0.3+0.65*edge)*pulse);
}
