//
//  Document.h
//  MaciASL
//
//  Created by PHPdev32 on 9/21/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@class DefinitionBlock;
@class iASLCompilationResult;

#import "AppDelegate.h"

@interface Document : NSDocument <NSTextViewDelegate, NSTextStorageDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFinderIndication>

@property (readonly) DefinitionBlock *nav;
@property NSUInteger jumpLine;
@property (readonly) iASLCompilationResult *result;

-(instancetype)initWithType:(NSString *)typeName tableName:(NSString *)tableName tableset:(NSURL *)tableset text:(NSString *)text error:(NSError *__autoreleasing *)outError;

-(IBAction)compile:(id)sender;
-(void)quickPatch:(NSString *)string;

@end
