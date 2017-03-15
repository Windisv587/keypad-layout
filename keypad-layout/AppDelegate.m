//
//  AppDelegate.m
//  window-key
//
//  Created by Jan-Gerd Tenberge on 14.03.17.
//  Copyright © 2017 Jan-Gerd Tenberge. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property NSStatusItem *statusItem;
@property NSRect rect;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
	Boolean trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

	if (trusted) {
		[self installHotkeys];
	}

	[self installStatusBarIcon];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (void)installStatusBarIcon {
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
	NSImage *image = [NSImage imageNamed:@"StatusBarImage"];
	image.size = NSMakeSize(30, 30);
	self.statusItem.image = image;
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Window Layouts"];
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Quit Keypad Layout" action:@selector(terminate:) keyEquivalent:@"q"];
	item.target = [NSApplication sharedApplication];
	[menu addItem:item];
	self.statusItem.menu = menu;
	self.statusItem.enabled = YES;
	self.statusItem.highlightMode = YES;
}

- (void)installHotkeys {
	CGEventMask interestedEvents = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged);
	CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, interestedEvents, hotkeyCallback, (__bridge void * _Nullable)(self));
	CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
}

CGEventRef hotkeyCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	CGEventFlags flags = CGEventGetFlags(event);
	AppDelegate *self = (__bridge AppDelegate *)refcon;
	
	if (!(flags & kCGEventFlagMaskControl)) {

		if ((type == kCGEventFlagsChanged) && !NSEqualRects(self.rect, NSZeroRect)) {
			self.rect = NSZeroRect;
			return NULL;
		} else {
			return event;
		}
	}
	
	if (type == NX_KEYDOWN) {
		// we convert our event into plain unicode
		UniChar characters[2];
		UniCharCount actualLength;
		UniCharCount outputLength = 1;
		CGEventKeyboardGetUnicodeString(event, outputLength, &actualLength, characters);
		char chars[2] = {characters[0], 0};
		
		if (strstr("123456789", chars)) {
			[self handleHotkeyChar:chars[0]];
			return NULL;
		}
		
	}
	
	// send event to next application
	return event;
}

- (NSRect)rectForCoordinateX:(CGFloat)x Y:(CGFloat)y {
	NSScreen *screen = [NSScreen mainScreen];
	NSRect workingRect = screen.visibleFrame;
	workingRect.origin.y = (screen.frame.size.height - screen.visibleFrame.size.height) - screen.visibleFrame.origin.y;
	CGFloat w = workingRect.size.width/3.0;
	CGFloat h = workingRect.size.height/3.0;
	CGFloat a = workingRect.origin.x;
	CGFloat b = workingRect.origin.y;
	NSRect rect = NSMakeRect(a + x * w, b + y * h, w, h);
	rect = NSInsetRect(rect, 1, 1);
	return rect;
}

- (void)handleHotkeyChar:(char)c {
	NSRect rect = NSZeroRect;
	
	switch (c) {
		case '7':
			rect = [self rectForCoordinateX:0 Y:0];
			break;
		case '8':
			rect = [self rectForCoordinateX:1 Y:0];
			break;
		case '9':
			rect = [self rectForCoordinateX:2 Y:0];
			break;
		case '4':
			rect = [self rectForCoordinateX:0 Y:1];
			break;
		case '5':
			rect = [self rectForCoordinateX:1 Y:1];
			break;
		case '6':
			rect = [self rectForCoordinateX:2 Y:1];
			break;
		case '1':
			rect = [self rectForCoordinateX:0 Y:2];
			break;
		case '2':
			rect = [self rectForCoordinateX:1 Y:2];
			break;
		case '3':
			rect = [self rectForCoordinateX:2 Y:2];
			break;
		default:
			break;
	}
	
	if (NSEqualRects(NSZeroRect, self.rect)) {
		self.rect = rect;
	} else {
		rect = NSUnionRect(self.rect, rect);
		self.rect = NSZeroRect;
		[self setFrontmostWindowFrame:rect];
	}

}

- (void)setFrontmostWindowFrame:(CGRect)frame {
	NSRunningApplication* app = [[NSWorkspace sharedWorkspace] frontmostApplication];
	pid_t pid = [app processIdentifier];
	AXUIElementRef appElem = AXUIElementCreateApplication(pid);
	AXUIElementRef window = NULL;
	
	if (AXUIElementCopyAttributeValue(appElem, kAXFocusedWindowAttribute, (CFTypeRef*)&window) != kAXErrorSuccess) {
		CFRelease(appElem);
		return;
	}
	
	AXValueRef sizeValue = AXValueCreate(kAXValueTypeCGSize, &frame.size);
	AXUIElementSetAttributeValue(window, kAXSizeAttribute, sizeValue);
	CFRelease(sizeValue);
	
	AXValueRef positionValue = AXValueCreate(kAXValueTypeCGPoint, &frame.origin);
	AXUIElementSetAttributeValue(window, kAXPositionAttribute, positionValue);
	CFRelease(positionValue);
	
	CFRelease(window);
	CFRelease(appElem);
}

@end
