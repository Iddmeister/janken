shader_type canvas_item;

uniform float lineWidth = 0.3;
uniform float linePosition = -1;

void fragment() {
	if ((UV.x+linePosition) >= (UV.y-lineWidth/2.0) && (UV.x+linePosition) <= (UV.y+lineWidth/2.0)) {
		COLOR = vec4(1, 1, 1, texture(TEXTURE, UV).a)
	} else {
		COLOR = texture(TEXTURE, UV)
	}
	
}