#version 150

in vec3 Position;
in vec4 Color;

in int gl_VertexID;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out float isHorizon;

#define HORIZONDIST 128

//settings

//#define BETA_TOOLTIPS
#define TOOLTIPS_BACKGROUND_COLOR vec3(0, 0, 0)
#define TOOLTIPS_LIGHT_COLOR vec3(0.988, 0.988, 0.98)
#define TOOLTIPS_DARK_COLOR vec3(0.737, 0.737, 0.718)

#define OUTLINE_SLIDERS
#define SLIDER_LIGHT_COLOR vec3(0.114, 0.106, 0.094)
#define SLIDER_SHADOW_COLOR vec3(0.702, 0.702, 0.682)

//

//fix for float ==
bool aproxEqual(float a, float b)
{
	return (a < b+0.00001 && a > b-0.00001);
}
bool aproxEqualV3(vec3 a, vec3 b)
{
	return (lessThan(a, b+0.0001)==bvec3(true) && lessThan(b-0.0001,a)==bvec3(true));
}

void main() {

    isHorizon = 0.0;

    if ((ModelViewMat * vec4(Position, 1.0)).z > -HORIZONDIST - 10.0) {
        isHorizon = 1.0;
    }
	
    vertexColor = Color;
	
	vec3 offset = vec3(0.0);
	
	//is tooltip?
	if (Color.g == 0.0)
	{
		//is background?
		if(aproxEqual(Color.a,0.94118) && aproxEqual(Color.r, 0.06275) && aproxEqual(Color.b, 0.06275))
		{
			#ifdef BETA_TOOLTIPS
				//12 ~ 17
				if(gl_VertexID > 7 && gl_VertexID < 12)
				{
					vertexColor.rgba = vec2(0.0,0.75).xxxy;
				}
				else
				{
					vertexColor.a = 0.0;
				}
			#else
				vertexColor.rgb = TOOLTIPS_BACKGROUND_COLOR;
				vertexColor.a = 0.8;
			#endif
		}
		
		#ifdef BETA_TOOLTIPS
			//is outline?
			else if(aproxEqual(Color.a,0.31373) && ((aproxEqual(Color.b,1.0) && aproxEqual(Color.r,0.31373)) || (aproxEqual(Color.b,0.49804) && aproxEqual(Color.r,0.15686)) ) )
			{
				vertexColor.a = 0.0;
			}
		#else
			//is outline?
			else if(aproxEqual(Color.a,0.31373))
			{
				//is outline light?
				if(aproxEqual(Color.b,1.0) && aproxEqual(Color.r,0.31373))
				{
					vertexColor.rgb = TOOLTIPS_LIGHT_COLOR;
					vertexColor.a = 0.7;
				}
				
				//is outline dark?
				else if(aproxEqual(Color.b,0.49804) && aproxEqual(Color.r,0.15686))
				{
					vertexColor.rgb = TOOLTIPS_DARK_COLOR;
					vertexColor.a = 0.5;
				}
			}
			#endif
	}
	
	//sliders VVV
	
	//is slider?
	else if (Color.a == 1.0)
	{
		//is shadow?
		if (aproxEqualV3(Color.rgb,vec3(0.50196)) && gl_VertexID > 3 && gl_VertexID < 8)
		{
			vertexColor.rgb = SLIDER_SHADOW_COLOR;
			vertexColor.a = 1.0;
		}
		
		//is light?
		else if (aproxEqualV3(Color.rgb,vec3(0.75294)) && gl_VertexID > 7 && gl_VertexID < 12)
		{
			#ifdef OUTLINE_SLIDERS
				//outline shading
				if(gl_VertexID == 10) {offset.y = 1.0;}//top right
				else if(gl_VertexID == 11) {offset.xy = vec2(1.0);}//top left
				else if(gl_VertexID == 8) {offset.x = 1.0;}//bottom left
				//9 = bottom right
			#endif
			
			vertexColor.rgb = SLIDER_LIGHT_COLOR;
			vertexColor.a = 1.0;
		}
		
		
		//is bg? //might not be posible to detect
		//if(Color.rgb == vec3(0.0) && gl_VertexID > -1 && gl_VertexID < 5)
		//{
		//	vertexColor.rgb = vec3(0.1,0.05,0.2);
		//}
	}
	
    gl_Position = ProjMat * ModelViewMat * vec4(Position + offset, 1.0);
}