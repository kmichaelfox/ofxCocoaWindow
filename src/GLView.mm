/////////////////////////////////////////////////////
//
//  GLView.mm
//  ofxCocoaWindow
//
//  Original code from,
//  http://developer.apple.com/library/mac/#samplecode/GLFullScreen/Introduction/Intro.html#//apple_ref/doc/uid/DTS40009820
//
//  Created by lukasz karluk on 16/11/11.
//  http://julapy.com/blog
//
/////////////////////////////////////////////////////

#import "GLView.h"
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

@implementation GLView

@synthesize delegate;
@synthesize bEnableSetupScreen;

- (NSOpenGLContext*) openGLContext
{
	return openGLContext;
}

- (NSOpenGLPixelFormat*) pixelFormat
{
	return pixelFormat;
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called because it will be called from a background thread
	// It's important to create one or you will leak objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [ delegate glViewUpdate ];
    
	[self drawView];
	
	[pool release];
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(GLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void) setupDisplayLink
{
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
}

- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context
{
    bEnableSetupScreen = true;
    
    NSOpenGLPixelFormatAttribute attribs[] =
    {
		kCGLPFAAccelerated,
        kCGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAColorSize, 32,
        kCGLPFANoRecovery,
		0
    };
	
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
    if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");
	
	// NSOpenGLView does not handle context sharing, so we draw to a custom NSView instead
	openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
	
	if (self = [super initWithFrame:frameRect]) {
		[[self openGLContext] makeCurrentContext];
		
		// Synchronize buffer swaps with vertical refresh rate
		GLint swapInt = 1;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
		
		[self setupDisplayLink];
		
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override 
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(reshape) 
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
	}
    
	return self;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}

- (void) lockFocus
{
	[super lockFocus];
	if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
}

- (void) reshape
{
	// This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
    ofSetupScreen();
    
	[[self openGLContext] update];
	
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

- (void) drawRect:(NSRect)dirtyRect
{
	if( CVDisplayLinkIsRunning(displayLink) )   // display link running, do not draw.
		return;
    
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
	// Make sure we draw to the right context
	[[self openGLContext] makeCurrentContext];
	
    ofSetupScreen();
    
    ofColor c = ofGetBackgroundColor();
    glClearColor(c.r/255.,c.g/255.,c.b/255.,c.a/255.);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	[[self openGLContext] flushBuffer]; 
	
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

- (void) drawView
{
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
	// Make sure we draw to the right context
	[[self openGLContext] makeCurrentContext];
	
    ofEvents().notifyUpdate();
    
    ofGetCurrentRenderer()->startRender();
    
    if( bEnableSetupScreen )
        ofSetupScreen();
    
	if( ofGetBackgroundAuto() )
    {
        ofColor c = ofGetBackgroundColor();
        glClearColor(c.r/255.,c.g/255.,c.b/255.,c.a/255.);
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}
    
    ofEvents().notifyDraw();
    
	[[self openGLContext] flushBuffer]; 
	
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
    
    ofGetCurrentRenderer()->finishRender();
}
 
- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (void) startAnimation
{
	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStart(displayLink);
}

- (void) stopAnimation
{
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
}

- (void) dealloc
{
	// Stop and release the display link
	CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
	
	// Destroy the context
	[openGLContext release];
	[pixelFormat release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSViewGlobalFrameDidChangeNotification
												  object:self];
	[super dealloc];
}

#pragma mark Events
//------------------------------------------------------------
-(void)flagsChanged:(NSEvent *)theEvent {
    NSEventModifierFlags flags = [theEvent modifierFlags];
    
    if( flags & NSCommandKeyMask ){
        ofEvents().notifyKeyPressed(OF_KEY_SUPER);
    } else if( flags & NSShiftKeyMask ){
        ofEvents().notifyKeyPressed(OF_KEY_SHIFT);
    } else if( flags & NSControlKeyMask ){
        ofEvents().notifyKeyPressed(OF_KEY_CONTROL);
    }   else if( flags & NSAlternateKeyMask ){
        ofEvents().notifyKeyPressed(OF_KEY_ALT);
    }
    //    } else if( flags & NSNumericPadKeyMask ){
    //        ofNotifyKeyPressed(OF_KEY_SUPER);
    //    } else if( flags & NSHelpKeyMask ){
    //        ofNotifyKeyPressed(OF_KEY_SUPER);
    //    } else if( flags & NSFunctionKeyMask ){
    //        ofNotifyKeyPressed(OF_KEY_);
    //    }
}

-(void)keyDown:(NSEvent *)theEvent 
{
	NSString *characters = [ theEvent characters ];
	if( [ characters length ] ) 
    {
		unichar key = [ characters characterAtIndex : 0 ];
        
        if( key ==  OF_KEY_ESC )
        {
            [ NSApp terminate : nil ];
        }
        else if( key == 63232 )
        {
            key = OF_KEY_UP;
        }
        else if( key == 63235 )
        {
            key = OF_KEY_RIGHT;
        }
        else if( key == 63233 )
        {
            key = OF_KEY_DOWN;
        }
        else if( key == 63234 )
        {
            key = OF_KEY_LEFT;
        }
        
		ofEvents().notifyKeyPressed( key );
	}
}

//------------------------------------------------------------
-(void)keyUp:(NSEvent *)theEvent {
	// TODO: make this more exhaustive if needed
	NSString *characters = [theEvent characters];
	if ([characters length]) {
		unichar key = [characters characterAtIndex:0];
		ofEvents().notifyKeyReleased(key);
	}
}

//------------------------------------------------------------
-(ofPoint) ofPointFromEvent:(NSEvent*)theEvent {
	NSPoint p = [theEvent locationInWindow];
	return ofPoint(p.x, self.frame.size.height - p.y, 0);
}

//------------------------------------------------------------
-(void)mouseDown:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMousePressed(p.x, p.y, 0);
}

//------------------------------------------------------------
-(void)rightMouseDown:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMousePressed(p.x, p.y, 2);
}

//------------------------------------------------------------
-(void)otherMouseDown:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMousePressed(p.x, p.y, 1);
}

//------------------------------------------------------------
-(void)mouseMoved:(NSEvent *)theEvent{
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseMoved(p.x, p.y);
}

//------------------------------------------------------------
-(void)mouseUp:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseReleased(p.x, p.y, 0);
}

//------------------------------------------------------------
-(void)rightMouseUp:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseReleased(p.x, p.y, 2);
}

//------------------------------------------------------------
-(void)otherMouseUp:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseReleased(p.x, p.y, 1);
}

//------------------------------------------------------------
-(void)mouseDragged:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseDragged(p.x, p.y, 0);
}

//------------------------------------------------------------
-(void)rightMouseDragged:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseDragged(p.x, p.y, 2);
}

//------------------------------------------------------------
-(void)otherMouseDragged:(NSEvent *)theEvent {
	ofPoint p = [self ofPointFromEvent:theEvent];
	ofEvents().notifyMouseDragged(p.x, p.y, 1);
}

//------------------------------------------------------------
-(void)scrollWheel:(NSEvent *)theEvent {
	// TODO: work on this, need to connect into OF scoll if possible
	//	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
}

@end
