//
//  AppDelegate.h
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@class SSDTGen;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDelegate, NSOutlineViewDelegate/*, NSFontManagerDelegate*/>

@property (readonly) NSArray *log, *themes, *deviceProperties;
@property (readonly) NSString *compiler;

-(void)logEntry:(NSString *)entry;
-(void)changeFont:(id)sender;
-(IBAction)showSummary:(id)sender;
-(IBAction)documentFromACPI:(id)sender;

@end

@interface FSTableView : NSTableView

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end

@interface FSPanel : NSPanel

-(BOOL)becomesKeyOnlyIfNeeded;

@end

@protocol NSTextFinderIndication

-(void)textViewDidShowFindIndicator:(NSNotification *)notification;

@end

@interface FSTextView : NSTextView

-(void)scrollRangeToVisible:(NSRange)range;

@end

@interface FSRulerView : NSRulerView

-(void)drawHashMarksAndLabelsInRect:(NSRect)rect;

@end
