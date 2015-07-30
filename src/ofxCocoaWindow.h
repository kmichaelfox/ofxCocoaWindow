/////////////////////////////////////////////////////
//
//  ofxCocoaWindow.h
//  ofxCocoaWindow
//
//  Created by lukasz karluk on 16/11/11.
//  http://julapy.com/blog
//
/////////////////////////////////////////////////////

#pragma once

#include "ofMain.h"
#include "ofAppBaseWindow.h"
#include "ofxCocoaDelegate.h"
#include "GLView.h"

class ofBaseApp;

class ofxCocoaWindowSettings : public ofGLWindowSettings {
public:
    
    bool        isOpaque;
    bool        hasWindowShadow;
    NSInteger   windowLevel;
    NSUInteger  styleMask;
    
    ofxCocoaWindowSettings():
    isOpaque(true)
    ,hasWindowShadow(true)
    ,windowLevel(NSNormalWindowLevel)
    ,styleMask(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask){
        
    }
    
    ofxCocoaWindowSettings(const ofGLWindowSettings & settings)
    :ofGLWindowSettings(settings)
    ,isOpaque(true)
    ,hasWindowShadow(true)
    ,windowLevel(NSNormalWindowLevel)
    ,styleMask(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask){
    }
    
//    See below!
//    ofGLWindowSettings()
//    :numSamples(4)
//    ,doubleBuffering(true)
//    ,redBits(8)
//    ,greenBits(8)
//    ,blueBits(8)
//    ,alphaBits(8)
//    ,depthBits(24)
//    ,stencilBits(0)
//    ,stereo(false)
//    ,visible(true)
//    ,iconified(false)
//    ,decorated(true)
//    ,resizable(true)
//    ,monitor(0){}
    
//    ofGLWindowSettings(const ofGLWindowSettings & settings)
//    :ofGLWindowSettings(settings)
//    ,numSamples(4)
//    ,doubleBuffering(true)
//    ,redBits(8)
//    ,greenBits(8)
//    ,blueBits(8)
//    ,alphaBits(8)
//    ,depthBits(24)
//    ,stencilBits(0)
//    ,stereo(false)
//    ,visible(true)
//    ,iconified(false)
//    ,decorated(true)
//    ,resizable(true)
//    ,monitor(0){}
    
// From GLFW window, should be supported someday
//    int numSamples;
//    bool doubleBuffering;
//    int redBits;
//    int greenBits;
//    int blueBits;
//    int alphaBits;
//    int depthBits;
//    int stencilBits;
//    bool stereo;
//    bool visible;
//    bool iconified;
//    bool decorated;
//    bool resizable;
//    int monitor;
//    shared_ptr<ofAppBaseWindow> shareContextWith;
};

class ofxCocoaWindow : public ofAppBaseGLWindow
{
public:
	 ofxCocoaWindow();
	~ofxCocoaWindow();

    static void loop();
    static bool doesLoop(){ return true; }
    static bool allowsMultiWindow(){ return true; }
    static bool needsPolling(){ return false; }
    static void pollEvents(){ }
    
    void setup(const ofxCocoaWindowSettings & settings);
	void setup(const ofGLWindowSettings & settings);
	void initializeWindow();
    
    void update();
    void draw();
    void close();
    
    ofCoreEvents & events();
    shared_ptr<ofBaseRenderer> & renderer();
    
	void hideCursor();
	void showCursor();

	void setFullscreen(bool fullScreen);
	void toggleFullscreen();

	void setWindowTitle(string title);
	void setWindowPosition(int x, int y);
	void setWindowShape(int w, int h);

	ofPoint		getWindowPosition();
	ofPoint		getWindowSize();
	ofPoint		getScreenSize();

	void			setOrientation(ofOrientation orientation);
	ofOrientation	getOrientation();
		
	int			getWidth();
	int			getHeight();	

	ofWindowMode    getWindowMode();

	int			getFrameNum();
	float		getFrameRate();
	double		getLastFrameTime();
	void		setFrameRate(float targetRate);

	void		enableSetupScreen();
	void		disableSetupScreen();
	
    // special ofxCocoaWindow stuff
    ofxCocoaDelegate * getDelegate();
    GLView           * getGlView();
    NSWindow         * getNSWindow();
    
protected:
	ofOrientation       orientation;
	ofBaseApp           *ofAppPtr;
	
	ofxCocoaDelegate    *delegate;
	NSAutoreleasePool   *pool; //not sure if needed
    
private:
    
    bool			bEnableSetupScreen;
    
    ofCoreEvents coreEvents;
    shared_ptr<ofBaseRenderer> currentRenderer;
    ofxCocoaWindowSettings settings;
};