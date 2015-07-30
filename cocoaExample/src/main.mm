
#include "ofMain.h"
#include "ofApp.h"

#include "ofxCocoaWindow.h"

#define USE_OFXCOCOASETTINGS

//========================================================================
int main( )
{
#ifndef USE_OFXCOCOASETTINGS
    ofxCocoaWindow cocoaWindow;
    ofSetupOpenGL(&cocoaWindow, 800, 600, OF_WINDOW);
	ofRunApp(new ofApp());
    
    // or, go wild!
#else
    ofxCocoaWindowSettings settings;
    settings.width = 800;
    settings.height = 600;
    settings.setPosition(ofVec2f(0,0));
    settings.isOpaque = false;
    settings.hasWindowShadow = false;
    settings.windowLevel = NSMainMenuWindowLevel;
    settings.styleMask = NSBorderlessWindowMask;
    
    ofInit();
    shared_ptr<ofxCocoaWindow> mainWindow = shared_ptr<ofxCocoaWindow>( new ofxCocoaWindow());
    ofGetMainLoop()->addWindow(mainWindow);
    mainWindow.get()->setup(settings);
    
    shared_ptr<ofApp> mainApp(new ofApp);
    
    ofRunApp(mainWindow, mainApp);
    ofRunMainLoop();
#endif
}
