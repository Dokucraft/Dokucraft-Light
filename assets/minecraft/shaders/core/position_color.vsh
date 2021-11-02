#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

out vec4 vertexColor;
out float isHorizon;
out float isSpyglass;
out vec2 uv;
flat out int customType;

#define HORIZONDIST 128

//settings

#define LOADING_BG_DARK_COLOR vec3(0.161, 0.122, 0.094)
#define LOADING_BG_COLOR vec3(0.161, 0.122, 0.094)

//might be usefull for replacing search bar
#define FIRST_BLACK vec4(0, 0, 0, 0.8)
#define FIRST_GRAY vec4(0.5, 0.5, 0.5, 0.5)
#define FIRST_WHITE vec4(1, 1, 1, 0.8)
#define RECIPE_BOOK_MISSING_COLOR vec4(1.0,0.1,0.23,0.38824)

//#define TOOLTIPS
#define TOOLTIPS_BACKGROUND_COLOR vec4(0, 0, 0, 0.8)
//#define TOOLTIPS_LIGHT_COLOR vec4(0.988, 0.988, 0.98, 0.7)
//#define TOOLTIPS_DARK_COLOR vec4(0.737, 0.737, 0.718, 0.5)

#define OUTLINE_SLIDERS
#define SLIDER_LIGHT_COLOR vec4(0.114, 0.106, 0.094, 1.0)
#define SLIDER_SHADOW_COLOR vec4(0.702, 0.702, 0.682, 1.0)

//out vec3 a;

//fix for float ==
bool aproxEqualLow(float a, float b)
{
	return (a < b+0.001 && a > b+(-0.001));
}
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
    isSpyglass = 0;
    customType = 0;
    if ((ModelViewMat * vec4(Position, 1.0)).z > -HORIZONDIST - 10.0) {
        isHorizon = 1.0;
    }
	if ((ModelViewMat * vec4(Position, 1.0)).z < -2050 && (ModelViewMat * vec4(Position, 1.0)).z > -2100) {
        isSpyglass = 1;
    }
	vertexColor = Color;
	
	vec3 offset = vec3(0.0);
	
	vec3 posWithoutOffset = (ProjMat * vec4(Position, 1.0)).xyz;
	
	//is on a screen corner? 
	if(aproxEqualLow(min(abs(posWithoutOffset.x),1.0), 1.0) && aproxEqualLow(min(abs(posWithoutOffset.y),1.0), 1.0))
	{
		//is first? & on z0
		if(gl_VertexID > -1 && gl_VertexID < 4 && Position.z == 0.0)
		{
			//is a color that the bg could be? //dark
			if(Color.r == 0.0 && Color.g == 0.0 && Color.b == 0.0)
			{
				vertexColor.rgb = LOADING_BG_DARK_COLOR;
			}
			
			//is a color that the bg could be? //red
			else if(aproxEqualV3(Color.rgb, vec3(0.93725,0.19608,0.23922) ))
			{
				vertexColor.rgb = LOADING_BG_COLOR;
			}
		}
	}
	
	//is gray?
	else if(aproxEqual(Color.r, 0.62745) && aproxEqual(Color.g, 0.62745) && aproxEqual(Color.b, 0.62745))
	{
		//is first?
		if(Color.a == 1.0 && gl_VertexID > -1 && gl_VertexID < 4)
		{
			vertexColor = FIRST_GRAY;
		}
	}
	//is tooltip?
	else if (Color.g == 0.0)
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
				vertexColor = TOOLTIPS_BACKGROUND_COLOR;
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
				customType = 2;
				uv = vec2(0.0);
				if (gl_VertexID == 28 || gl_VertexID == 32 || gl_VertexID == 31 || gl_VertexID == 35 || (gl_VertexID >= 24 && gl_VertexID <= 27)) {
					uv.x = 1.0;
				} else if (gl_VertexID == 29 || gl_VertexID == 33 || gl_VertexID == 30 || gl_VertexID == 34 || (gl_VertexID >= 20 && gl_VertexID <= 23)) {
					uv.x = -1.0;
				}

				//is outline light?
				if(aproxEqual(Color.b,1.0) && aproxEqual(Color.r,0.31373))
				{
					//vertexColor = TOOLTIPS_LIGHT_COLOR;
					uv.y = -1.0;
				}

				//is outline dark?
				else if(aproxEqual(Color.b,0.49804) && aproxEqual(Color.r,0.15686))
				{
					//vertexColor = TOOLTIPS_DARK_COLOR;
					uv.y = 1.0;
				}
			}
		#endif
		
		//is black?
		else if (Color.r == 0.0 && Color.b == 0.0)
		{
			//is first?
			if(Color.a == 1.0 && gl_VertexID > -1 && gl_VertexID < 4)
			{
				vertexColor = FIRST_BLACK;
			}
		}
		
		//is recipe book missing overlay?
		else if (aproxEqual(Color.a,0.18824) && Color.r == 1.0 && Color.b == 0.0 && gl_VertexID > -1 && gl_VertexID < 4)
		{
			vertexColor.rgba = RECIPE_BOOK_MISSING_COLOR;
		}
	}
	
	//is white?
	else if (aproxEqualV3(Color.rgb,vec3(1.0)))
	{
		//is first?
		if(aproxEqual(Color.a,1.0) && gl_VertexID > -1 && gl_VertexID < 4)
		{
			vertexColor = FIRST_WHITE;
		}
		
		//is hover?
		if(aproxEqual(Color.a,0.50196) && gl_VertexID > -1 && gl_VertexID < 4)
		{
			customType = 1;
			float padding = 1.0;
			if (sin(GameTime * 6000.0) > 0) padding += 1.0;

            switch(gl_VertexID % 4)
            {
            case 0:
                uv = vec2(1.0, -1.0);
                offset.x = padding;
                offset.y = -padding;
                break;
            case 1:
                uv = vec2(-1.0, -1.0);
                offset.x = -padding;
                offset.y = -padding;
                break;
            case 2:
                uv = vec2(-1.0, 1.0);
                offset.x = -padding;
                offset.y = padding;
                break;
            case 3:
                uv = vec2(1.0, 1.0);
                offset.x = padding;
                offset.y = padding;
                break;
            }
		}
	}
	
	else if (Color.a == 1.0)
	{
		//is slider shadow?
		if (aproxEqualV3(Color.rgb,vec3(0.50196)) && gl_VertexID > 3 && gl_VertexID < 8)
		{
			vertexColor = SLIDER_SHADOW_COLOR;
		}
		
		//is slider light?
		else if (aproxEqualV3(Color.rgb,vec3(0.75294)) && gl_VertexID > 7 && gl_VertexID < 12)
		{
			#ifdef OUTLINE_SLIDERS
				//outline shading
				if(gl_VertexID == 10) {offset.y = 1.0;}//top right
				else if(gl_VertexID == 11) {offset.xy = vec2(1.0);}//top left
				else if(gl_VertexID == 8) {offset.x = 1.0;}//bottom left
				//9 = bottom right
			#endif
			
			vertexColor = SLIDER_LIGHT_COLOR;
		}
	}
	
    gl_Position = ProjMat * ModelViewMat * vec4(Position + offset, 1.0);
}