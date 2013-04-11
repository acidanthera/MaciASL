//
//  AppDelegate.h
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Document.h"
#import "SSDT.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDelegate/*, NSFontManagerDelegate*/>{
    @private
    SSDTGen *_ssdt;
}

@property NSMutableArray *log;
@property NSString *compiler;
@property (readonly) SSDTGen *ssdt;
@property (readonly) NSArray *themes;
@property (assign) IBOutlet NSMenu *tables;
@property (assign) IBOutlet NSView *general;
@property (assign) IBOutlet NSView *iasl;
@property (assign) IBOutlet NSView *sources;
@property (assign) IBOutlet NSWindow *logView;
@property (assign) IBOutlet NSWindow *summaryView;
@property (assign) IBOutlet NSTableView *sourceView;
@property (assign) IBOutlet NSArrayController *sourceController;

-(IBAction)showSSDT:(id)sender;
-(IBAction)newSource:(id)sender;
-(Document *)newDocument:(NSString *)text withName:(NSString *)name;
-(IBAction)swapPreference:(id)sender;
-(IBAction)documentFromACPI:(id)sender;
-(IBAction)showLog:(id)sender;
-(IBAction)showSummary:(id)sender;
-(void)logEntry:(NSString *)entry;

@end

@interface LogEntry : NSObject

@property NSDate *timestamp;
@property NSString *entry;

+(LogEntry *)create:(NSString *)entry;

@end

@interface FSTableView : NSTableView

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end

@interface FSPanel : NSPanel

-(BOOL)becomesKeyOnlyIfNeeded;

@end

@interface FSTextView : NSTextView

-(void)scrollRangeToVisible:(NSRange)range;

@end

@interface FSRulerView : NSRulerView

-(void)drawHashMarksAndLabelsInRect:(NSRect)rect;

@end
