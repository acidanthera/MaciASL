//
//  Colorize.h
//  MaciASL
//
//  Created by PHPdev32 on 9/30/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface ColorTheme : NSObject

@property NSColor *background;
@property NSColor *text;
@property NSColor *string;
@property NSColor *number;
@property NSColor *comment;
@property NSColor *operator;
@property NSColor *opNoArg;
@property NSColor *keyword;
@property NSColor *resource;
@property NSColor *predefined;

+(NSDictionary *)allThemes;
+(ColorTheme *)create:(NSColor *)text background:(NSColor *)background string:(NSColor *)string number:(NSColor *)number comment:(NSColor *)comment operator:(NSColor *)operator opNoArg:(NSColor *)opNoArg keyword:(NSColor *)keyword resource:(NSColor *)resource predefined:(NSColor *)predefined;

@end

@interface Colorize : NSObject <NSTextStorageDelegate>

@property NSTextView *view;
@property NSLayoutManager *mgr;
@property ColorTheme *theme;

+(Colorize *)create:(NSView *)view;

-(void)coalesce:(NSNotification *)aNotification;
-(void)colorize;

@end
