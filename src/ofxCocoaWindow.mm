/////////////////////////////////////////////////////
//
//  ofxCocoaWindow.mm
//  ofxCocoaWindow
//
//  Created by lukasz karluk on 16/11/11.
//  http://julapy.com/blog
//
/////////////////////////////////////////////////////

#include "ofxCocoaWindow.h"

#import <AppKit/AppKit.h>

//void ofGLReadyCallback();

static ofxCocoaWindow * instance;

//------------------------------------------------------------
ofxCocoaWindow :: ofxCocoaWindow()
{
	orientation	= OF_ORIENTATION_DEFAULT; // for now this goes here.
    instance = this;
    bEnableSetupScreen	= true;
}

ofxCocoaWindow :: ~ofxCocoaWindow ()
{
    //
}

//------------------------------------------------------------
void ofxCocoaWindow :: setup( const ofGLWindowSettings & _settings )
{
    settings = _settings;
    if( settings.windowMode == OF_GAME_MODE )
    {
        cout << "OF_GAME_MODE not supported in ofxCocoaWindow. Please use OF_WINDOW or OF_FULLSCREEN" << endl;
        return;
    }
    
    pool = [ NSAutoreleasePool new ];
//    [ NSApplication sharedApplication ];
    
    // this creates the Window and OpenGLView in the MyDelegate initialization
    delegate = [ [ [ ofxCocoaDelegate alloc ] initWithWidth : settings.width
                                                     height : settings.width
                                                 windowMode : settings.windowMode ] autorelease ];

    [ [ NSApplication sharedApplication ] setDelegate : delegate ];
    
    if((settings.glVersionMajor==3 && settings.glVersionMinor>=2) || settings.glVersionMajor>=4){
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    }
    if(settings.glVersionMajor>=3){
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
        currentRenderer = shared_ptr<ofBaseRenderer>(new ofGLProgrammableRenderer(this));
    }else{
        currentRenderer = shared_ptr<ofBaseRenderer>(new ofGLRenderer(this));
    }
    
    static bool inited = false;
    if(!inited){
        glewExperimental = GL_TRUE;
        GLenum err = glewInit();
        if (GLEW_OK != err)
        {
            /* Problem: glewInit failed, something is seriously wrong. */
            ofLogError("ofAppRunner") << "couldn't init GLEW: " << glewGetErrorString(err);
            return;
        }
        inited = true;
    }
    
    if(currentRenderer->getType()==ofGLProgrammableRenderer::TYPE){
        static_cast<ofGLProgrammableRenderer*>(currentRenderer.get())->setup(settings.glVersionMajor,settings.glVersionMinor);
    }else{
        static_cast<ofGLRenderer*>(currentRenderer.get())->setup();
    }
    
    //ofGLReadyCallback();
}

//------------------------------------------------------------
void ofxCocoaWindow :: initializeWindow ()
{
	// no callbacks needed.
}

//--------------------------------------------
ofCoreEvents & ofxCocoaWindow::events(){
    return coreEvents;
}

//--------------------------------------------
shared_ptr<ofBaseRenderer> & ofxCocoaWindow::renderer(){
    return currentRenderer;
}

//--------------------------------------------
void ofxCocoaWindow::update(){
    events().notifyUpdate();
}

//--------------------------------------------
void ofxCocoaWindow::draw(){
    cout << "YAS"<<endl;
    currentRenderer->startRender();
    if( bEnableSetupScreen ) currentRenderer->setupScreen();
    
    events().notifyDraw();
    
    if (currentRenderer->getBackgroundAuto() == false){
        // in accum mode resizing a window is BAD, so we clear on resize events.
//        if (nFramesSinceWindowResized < 3){
//            currentRenderer->clear();
//        }
    }
//    if(settings.doubleBuffering){
//        // hm
////        glfwSwapBuffers(windowP);
//    } else{
        glFlush();
//    }
    
    currentRenderer->finishRender();
    
//    nFramesSinceWindowResized++;
}

//--------------------------------------------
void ofxCocoaWindow::loop(){
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
//    
//    instance->events().notifySetup();
//    instance->events().notifyUpdate();
    
    
    // This launches the NSapp functions in  MyDelegate
    [NSApp run];
    
    [instance->pool drain];
}

void ofxCocoaWindow::close(){
    events().notifyExit();
    events().disable();
    
    
}

//------------------------------------------------------------
float ofxCocoaWindow :: getFrameRate()
{
	return [ delegate getFrameRate ];
}

//------------------------------------------------------------
double ofxCocoaWindow :: getLastFrameTime()
{
	return [ delegate getLastFrameTime ];
}

//------------------------------------------------------------
int ofxCocoaWindow :: getFrameNum()
{
	return [ delegate getFrameNum ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: setWindowTitle( string title )
{
	// TODO.
}

//------------------------------------------------------------
ofPoint ofxCocoaWindow :: getWindowSize()
{
	return ofPoint( getWidth(), getHeight(), 0 );
}

//------------------------------------------------------------
ofPoint ofxCocoaWindow :: getWindowPosition()
{
	NSRect viewFrame    = [ delegate getViewFrame ];
	NSRect windowFrame  = [ delegate getWindowFrame ];
	NSRect screenRect   = [ delegate getScreenFrame ];
	return ofPoint( windowFrame.origin.x, screenRect.size.height-windowFrame.origin.y-viewFrame.size.height, 0 );
}

//------------------------------------------------------------
ofPoint ofxCocoaWindow :: getScreenSize()
{
	NSRect screenRect = [ delegate getScreenFrame ];
	return ofPoint( screenRect.size.width, screenRect.size.height, 0 );
}

//------------------------------------------------------------
int ofxCocoaWindow :: getWidth()
{
	if( orientation == OF_ORIENTATION_DEFAULT || orientation == OF_ORIENTATION_180 )
		return [ delegate getViewFrame ].size.width;
	return [ delegate getViewFrame ].size.height;
}

//------------------------------------------------------------
int ofxCocoaWindow :: getHeight()
{
	if( orientation == OF_ORIENTATION_DEFAULT || orientation == OF_ORIENTATION_180 )
		return [ delegate getViewFrame ].size.height;
	return [ delegate getViewFrame ].size.width;
}

//------------------------------------------------------------
void ofxCocoaWindow :: setOrientation( ofOrientation orientationIn )
{
	orientation = orientationIn;
}

//------------------------------------------------------------
ofOrientation ofxCocoaWindow :: getOrientation()
{
	return orientation;
}

//------------------------------------------------------------
void ofxCocoaWindow :: setWindowPosition( int x, int y ) 
{
    if( [ delegate windowMode ] == OF_FULLSCREEN )
        return; // only do this in OF_WINDOW mode.
    
	NSRect viewFrame  = [ delegate getViewFrame ];
	NSRect screenRect = [ delegate getScreenFrame ];
	
	NSPoint position = NSMakePoint( x, screenRect.size.height - viewFrame.size.height - y );
    [ delegate setWindowPosition : position ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: setWindowShape( int w, int h )
{
    if( [ delegate windowMode ] == OF_FULLSCREEN )
        return; // only do this in OF_WINDOW mode.
    
    NSRect windowFrame  = [ delegate getWindowFrame ];
	NSRect viewFrame    = [ delegate getViewFrame ];
	NSRect screenRect   = [ delegate getScreenFrame ];
    
    int x, y, g;
    x = windowFrame.origin.x;
    y = screenRect.size.height - viewFrame.size.height - windowFrame.origin.y;
	
    NSRect resizedWindowFrame = NSZeroRect;
    resizedWindowFrame.origin = NSMakePoint( x, screenRect.size.height - h - y );
	resizedWindowFrame.size   = NSMakeSize( w, h );
	
	[ delegate setWindowShape : resizedWindowFrame ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: hideCursor() 
{
	[ NSCursor hide ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: showCursor() 
{
	[ NSCursor unhide ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: setFrameRate ( float targetRate )
{
	NSLog( @"When using the Core Video Display Link, setting frame rate is not possible. Use setUpdateRate to set the update frequency to something different than the frame rate." );
}

//------------------------------------------------------------
ofWindowMode ofxCocoaWindow :: getWindowMode()
{
	return [ delegate windowMode ];
}

//------------------------------------------------------------
void ofxCocoaWindow :: toggleFullscreen() 
{
	if( [ delegate windowMode ] == OF_GAME_MODE )
        return;
	
	if( [ delegate windowMode ] == OF_WINDOW )
    {
		[ delegate goFullScreenOnAllDisplays ];
    }
    else if( [ delegate windowMode ] == OF_FULLSCREEN )
    {
		[ delegate goWindow ];
    }
}

//------------------------------------------------------------
void ofxCocoaWindow :: setFullscreen(bool fullscreen)
{
	if( [ delegate windowMode ] == OF_GAME_MODE )
        return;
	
    if( fullscreen && [ delegate windowMode ] != OF_FULLSCREEN )
    {
		[ delegate goFullScreenOnAllDisplays ];
    }
    else if( !fullscreen && [ delegate windowMode ] != OF_WINDOW )
    {
		[ delegate goWindow ];
    }
}

//------------------------------------------------------------
void ofxCocoaWindow :: enableSetupScreen()
{
	[ delegate enableSetupScreen ];
    bEnableSetupScreen = true;
}

//------------------------------------------------------------
void ofxCocoaWindow :: disableSetupScreen()
{
    [ delegate disableSetupScreen ];
    bEnableSetupScreen = false;
}