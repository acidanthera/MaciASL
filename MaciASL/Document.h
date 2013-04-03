//
//  Document.h
//  MaciASL
//
//  Created by PHPdev32 on 9/21/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Patch.h"
@class DefinitionBlock;
@class Colorize;

@interface Document : NSDocument <NSTextViewDelegate, NSTextStorageDelegate, NSOutlineViewDelegate> {
    @private
    DefinitionBlock *_oldNav;
    Patcher *_patch;
}

@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSOutlineView *navView;
@property (assign) IBOutlet NSTreeController *navController;
@property (assign) IBOutlet NSSearchField *filter;
@property (assign) IBOutlet NSWindow *jump;
@property NSUInteger jumpLine;
@property NSTextStorage *text;
@property DefinitionBlock *nav;
@property (readonly) Patcher *patch;
@property NSDictionary *summary;
@property Colorize *colorize;

-(void)setDocument:(NSString *)string;
-(IBAction)filterTree:(id)sender;
-(IBAction)hexConvert:(id)sender;
-(IBAction)jumpToLine:(id)sender;
-(IBAction)landOnLine:(id)sender;
-(void)quickPatch:(NSString *)string;
-(IBAction)compile:(id)sender;
-(IBAction)patch:(id)sender;

@end
