#include <glad/glad.h>
#include <GLFW/glfw3.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "Shader.h"
#include "wtypes.h"
#include <time.h>
#include <iostream>

// FPS, iFrame counter.
int initialTime = time(NULL), finalTime, frameCount;
// timing
float deltaTime = 0.0f;
float lastFrame = 0.0f;

// We need this to be able to resize our window.
void framebuffer_size_callback( GLFWwindow* window, int width, int height );
// We need this to be able to close our window when pressing a key.
void processInput( GLFWwindow* window );
// We need this to be able to call our load image function from below main.
unsigned int loadTexture(const char *path);

// Our mouse button click flag.
float pressed = 0.0;

// Our image size.
int WIDTH;
int HEIGHT;

// Get the horizontal and vertical screen sizes in pixel
void GetDesktopResolution(int& horizontal, int& vertical)
{
	RECT desktop;
	// Get a handle to the desktop window
	const HWND hDesktop = GetDesktopWindow();
	// Get the size of screen to the variable desktop
	GetWindowRect(hDesktop, &desktop);
	// The top left corner will have coordinates (0,0)
	// and the bottom right corner will have coordinates
	// (horizontal, vertical)
	horizontal = desktop.right;
	vertical = desktop.bottom;
}

// Our mouse.
static void cursorPositionCallback( GLFWwindow *window, double xPos, double yPos );
// Our mouse button press.
static void mouseButtonCallback( GLFWwindow *window, int button, int action, int mods );

int main() 
{
	
	// Get our window size according to each screen we run our program.
	//GetDesktopResolution( WIDTH, HEIGHT );

	WIDTH = 640, HEIGHT = 360;

	// We initialize glfw and specify which versions of OpenGL to target.
	glfwInit();
	glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3 );
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 3 );
	glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );

	// Our window object.
	GLFWwindow* window = glfwCreateWindow(WIDTH, HEIGHT, "NavierStokeish", NULL, NULL);
	if (window == NULL)
	{

		std::cout << "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;

	}
	glfwMakeContextCurrent(window);
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

	// Initialize the mouse.
	glfwSetCursorPosCallback( window, cursorPositionCallback );
	// Initialize the mouse button.
	glfwSetMouseButtonCallback( window, mouseButtonCallback );

	// Load glad, we need this library to specify system specific functions.
	if( !gladLoadGLLoader( ( GLADloadproc ) glfwGetProcAddress ) )
	{

		std::cout << "Failed to initialize GLAD" << std::endl;
		return -1;

	}

	// We build and compile our shader program.
	Shader Image( "vertex.glsl", "Image.glsl" );
	Shader BufferA( "vertex.glsl", "BufferA.glsl" );
	Shader BufferB( "vertex.glsl", "BufferB.glsl" );
	Shader BufferC( "vertex.glsl", "BufferC.glsl" );

	// We define the points in space that we want to render.
	float vertices[] =
	{
		
		// Positions.            // FragCoord
		-1.0f,  -1.0f, 0.0f,     //-1.0f,  1.0f,
		-1.0f,   1.0f, 0.0f,     //1.0f,  1.0f,
		 1.0f,   1.0f, 0.0f,     //1.0f, -1.0f,
		 1.0f,  -1.0f, 0.0f      //-1.0f, -1.0f 

	};

	// We define our Element Buffer Object indices so that if we have vertices that overlap,
	// we dont have to render twice, 50% overhead.
	unsigned int indices[] = 
	{
	
		0, 1, 3,
		1, 2, 3

	};

	// We create a buffer ID so that we can later assign it to our buffers.
	unsigned int VBO, VAO, EBO;
	glGenVertexArrays( 1, &VAO );
	glGenBuffers( 1, &VBO );
	glGenBuffers( 1, &EBO );

	// Bind Vertex Array Object.
	glBindVertexArray( VAO );

	// Copy our vertices array in a buffer for OpenGL to use.
	// We assign our buffer ID to our new buffer and we overload it with our triangles array.
	glBindBuffer( GL_ARRAY_BUFFER, VBO );
	glBufferData( GL_ARRAY_BUFFER, sizeof( vertices ), vertices, GL_STATIC_DRAW );

	// Copy our indices in an array for OpenGL to use.
	glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, EBO );
	glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof( indices ), indices, GL_STATIC_DRAW );

	// Set our vertex attributes pointers.
	glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof( float ), ( void* ) 0 );
	glEnableVertexAttribArray( 0 );

	// Unbind the VBO.
	glBindBuffer( GL_ARRAY_BUFFER, 0 );

	// Unbind the VAO.
	glBindVertexArray( 0 );

	// Load them textures.
	//unsigned int tex = loadTexture( "Cassini-Projection-2.jpg" );
	
	BufferA.use();
	BufferA.setInt( "iChannel0", 0 );
	BufferA.setInt( "iChannel1", 1 );

	BufferB.use();
	BufferB.setInt( "iChannel0", 1 );
	BufferB.setInt( "iChannel1", 0 );

	BufferC.use();
	BufferC.setInt( "iChannel0", 0 );
	BufferC.setInt( "iChannel1", 1 );

	Image.use();
	Image.setInt( "iChannel0", 0 );
	Image.setInt( "iChannel1", 1 );
	Image.setInt( "iChannel2", 2 );

	// BufferA Ping Pong FrameBuffers
	// Framebuffer configuration.
	unsigned int frameBuffer;
	glGenFramebuffers( 1, &frameBuffer );
	glBindFramebuffer( GL_FRAMEBUFFER, frameBuffer );

	// Create a colour attachment texture.
	unsigned int textureColourBuffer;
	glGenTextures( 1, &textureColourBuffer );
	glBindTexture( GL_TEXTURE_2D, textureColourBuffer );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBuffer, 0 );
	
	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer( GL_FRAMEBUFFER, 0 );

	// BufferA frameBuffer configuration.
	// Framebuffer configuration.
	unsigned int frameBufferOne;
	glGenFramebuffers(1, &frameBufferOne);
	glBindFramebuffer(GL_FRAMEBUFFER, frameBufferOne);

	// Create a colour attachment texture.
	unsigned int textureColourBufferOne;
	glGenTextures( 1, &textureColourBufferOne );
	glBindTexture( GL_TEXTURE_2D, textureColourBufferOne);
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBufferOne, 0 );

	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer( GL_FRAMEBUFFER, 0 );

	// BufferB frameBuffer configurations.
	// Framebuffer configuration.
	unsigned int frameBufferTwo;
	glGenFramebuffers( 1, &frameBufferTwo );
	glBindFramebuffer( GL_FRAMEBUFFER, frameBufferTwo );

	// Create a colour attachment texture.
	unsigned int textureColourBufferTwo;
	glGenTextures( 1, &textureColourBufferTwo );
	glBindTexture( GL_TEXTURE_2D, textureColourBufferTwo );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBufferTwo, 0 );

	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	// Framebuffer configuration.
	unsigned int frameBufferThree;
	glGenFramebuffers( 1, &frameBufferThree );
	glBindFramebuffer( GL_FRAMEBUFFER, frameBufferThree );

	// Create a colour attachment texture.
	unsigned int textureColourBufferThree;
	glGenTextures( 1, &textureColourBufferThree );
	glBindTexture( GL_TEXTURE_2D, textureColourBufferThree );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBufferThree, 0 );

	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer( GL_FRAMEBUFFER, 0 );

	// BufferC frameBuffer configurations.
	// Framebuffer configuration.
	unsigned int frameBufferFour;
	glGenFramebuffers(1, &frameBufferFour);
	glBindFramebuffer(GL_FRAMEBUFFER, frameBufferFour);

	// Create a colour attachment texture.
	unsigned int textureColourBufferFour;
	glGenTextures( 1, &textureColourBufferFour );
	glBindTexture( GL_TEXTURE_2D, textureColourBufferFour );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBufferFour, 0 );

	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer( GL_FRAMEBUFFER, 0 );

	// Framebuffer configuration.
	unsigned int frameBufferFive;
	glGenFramebuffers( 1, &frameBufferFive );
	glBindFramebuffer( GL_FRAMEBUFFER, frameBufferFive );

	// Create a colour attachment texture.
	unsigned int textureColourBufferFive;
	glGenTextures( 1, &textureColourBufferFive );
	glBindTexture( GL_TEXTURE_2D, textureColourBufferFive );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColourBufferFive, 0 );

	if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE )
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	glBindFramebuffer( GL_FRAMEBUFFER, 0 );

	// We want to know if the frame we are rendering is even or odd.
	bool even = true;

	// Render Loop.
	while( !glfwWindowShouldClose( window ) )
	{
	
		// Input.
		processInput( window );

		// Render.

		// Bind to frameBuffer and draw scene as normally would to colour texture.
		glBindFramebuffer( GL_FRAMEBUFFER, even ? frameBuffer : frameBufferOne );

		glClearColor( 0.2f, 0.3f, 0.1f, 1.0f );
		glClear( GL_COLOR_BUFFER_BIT );

		BufferA.use();
		float currentFrame = glfwGetTime();
		//Set the iTimeDelta uniform.
		float deltaTime = currentFrame - lastFrame;
		lastFrame = currentFrame;
		BufferA.setFloat( "iTimeDelta", deltaTime );
		// Set the iTime uniform.
		float timeValue = currentFrame;
		BufferA.setFloat( "iTime", timeValue );
		// Set the iResolution uniform.
		BufferA.setVec2( "iResolution", WIDTH, HEIGHT );
		// Input iMouse.
		double xPos, yPos;
		glfwGetCursorPos( window, &xPos, &yPos );
		yPos = HEIGHT - yPos;
		BufferA.setVec3( "iMouse", xPos, yPos, pressed );

		glBindVertexArray( VAO );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferOne : textureColourBuffer );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferThree : textureColourBufferTwo );
		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0 );
		glBindVertexArray( 0 );

		glBindFramebuffer( GL_FRAMEBUFFER, 0 );

		// BufferB
		glBindFramebuffer( GL_FRAMEBUFFER, even ? frameBufferTwo : frameBufferThree );

		glClearColor( 0.2f, 0.3f, 0.1f, 1.0f );
		glClear( GL_COLOR_BUFFER_BIT );

		BufferB.use();
		//Set the iTimeDelta uniform.
		BufferB.setFloat( "iTimeDelta", deltaTime );
		// Set the iTime uniform.
		BufferB.setFloat( "iTime", timeValue );
		// Set the iResolution uniform.
		BufferB.setVec2( "iResolution", WIDTH, HEIGHT );
		// Input iMouse.
		BufferB.setVec3( "iMouse", xPos, yPos, pressed );

		glBindVertexArray( VAO );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferOne : textureColourBuffer );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferThree : textureColourBufferTwo );
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
		glBindVertexArray( 0 );

		glBindFramebuffer( GL_FRAMEBUFFER, 0 );

		glClearColor( 1.0f, 1.0f, 1.0f, 1.0f );
		glClear( GL_COLOR_BUFFER_BIT );

		// BufferC
		glBindFramebuffer( GL_FRAMEBUFFER, even ? frameBufferFour : frameBufferFive );

		glClearColor( 0.2f, 0.3f, 0.1f, 1.0f );
		glClear( GL_COLOR_BUFFER_BIT );

		BufferC.use();
		//Set the iTimeDelta uniform.
		BufferC.setFloat( "iTimeDelta", deltaTime );
		// Set the iTime uniform.
		BufferC.setFloat( "iTime", timeValue );
		// Set the iResolution uniform.
		BufferC.setVec2( "iResolution", WIDTH, HEIGHT );
		// Input iMouse.
		BufferC.setVec3( "iMouse", xPos, yPos, pressed );

		glBindVertexArray( VAO );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferFive : textureColourBufferFour );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferThree : textureColourBufferTwo );
		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0 );
		glBindVertexArray( 0 );

		glBindFramebuffer( GL_FRAMEBUFFER, 0 );

		glClearColor( 1.0f, 1.0f, 1.0f, 1.0f );
		glClear( GL_COLOR_BUFFER_BIT );

		Image.use();
		// Set the iResolution uniform.
		Image.setVec2( "iResolution", WIDTH, HEIGHT );
		// Set the iTime uniform.
		Image.setFloat( "iTime", timeValue );
		glBindVertexArray( VAO );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferOne : textureColourBuffer );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferThree : textureColourBufferTwo );
		glActiveTexture( GL_TEXTURE2 );
		glBindTexture( GL_TEXTURE_2D, even ? textureColourBufferFive : textureColourBufferFour );
		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0 );

		glfwSwapBuffers( window );
		glfwPollEvents();

		even = !even;

		frameCount++;
		finalTime = time( NULL );
		if( finalTime - initialTime > 0 )
		{
		
			std::cout << "FPS : " << frameCount / ( finalTime - initialTime ) << std::endl;
			frameCount = 0;
			initialTime = finalTime;

		}
	
	}

	// De-allocate all resources once they've outlived their purpose.
	glDeleteVertexArrays( 1, &VAO );
	glDeleteBuffers( 1, &VBO );
	glDeleteBuffers( 1, &EBO );

	glfwTerminate();
	return 0;
}

void processInput( GLFWwindow *window )
{

	if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
		glfwSetWindowShouldClose( window, true );

}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{

	glViewport(0, 0, width, height);

}

static void cursorPositionCallback( GLFWwindow *window, double xPos, double yPos )
{

	xPos = 2.0 * xPos / WIDTH - 1;
	yPos = -2.0 * yPos / HEIGHT + 1;

}

static void mouseButtonCallback(GLFWwindow *window, int button, int action, int mods) 
{

	if( button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS )
	{
	
		if( pressed == 0.0 )
		{
		
			pressed = 1.0;
		
		}
	
	}

	if ( button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_RELEASE )
	{

		if ( pressed == 1.0 )
		{

			pressed = 0.0;

		}

	}

	std::cout << std::boolalpha << pressed << std::endl;

}

// utility function for loading a 2D texture from file
// ---------------------------------------------------
unsigned int loadTexture(char const * path)
{
	unsigned int textureID;
	glGenTextures(1, &textureID);

	int width, height, nrComponents;
	stbi_set_flip_vertically_on_load(true);
	unsigned char *data = stbi_load(path, &width, &height, &nrComponents, 0);
	if (data)
	{
		GLenum format;
		if (nrComponents == 1)
			format = GL_RED;
		else if (nrComponents == 3)
			format = GL_RGB;
		else if (nrComponents == 4)
			format = GL_RGBA;

		glBindTexture(GL_TEXTURE_2D, textureID);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, height, 0, format, GL_UNSIGNED_BYTE, data);
		glGenerateMipmap(GL_TEXTURE_2D);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		stbi_image_free(data);
	}
	else
	{
		std::cout << "Texture failed to load at path: " << path << std::endl;
		stbi_image_free(data);
	}

	return textureID;
}