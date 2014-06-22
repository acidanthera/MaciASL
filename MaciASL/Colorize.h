//
//  Colorize.h
//  MaciASL
//
//  Created by PHPdev32 on 9/30/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface ColorTheme : NSObject

@property (readonly) NSColor *background, *text, *string, *number, *comment, *operator, *opNoArg, *keyword, *resource, *predefined;

+(NSDictionary *)allThemes;

@end

@interface Colorize : NSObject <NSTextStorageDelegate>

-(instancetype)initWithTextView:(NSTextView *)textView;

@end
