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

class ofBaseApp;

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
    
	void setup(const ofGLWindowSettings & settings);
	void initializeWindow();
//	void runAppViaInfiniteLoop(ofBaseApp * appPtr);
    
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
	
protected:
	ofOrientation       orientation;
	ofBaseApp           *ofAppPtr;
	
	ofxCocoaDelegate    *delegate;
	NSAutoreleasePool   *pool; //not sure if needed
    
private:
    
    bool			bEnableSetupScreen;
    
    ofCoreEvents coreEvents;
    shared_ptr<ofBaseRenderer> currentRenderer;
    ofGLWindowSettings settings;
};