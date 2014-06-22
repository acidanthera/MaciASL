//
//  DocumentController.h
//  MaciASL
//
//  Created by PHPdev32 on 10/14/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@class Document;

@interface DocumentController : NSDocumentController

@property (readonly) NSArray *tableNames;
@property NSUInteger tableSelection;

-(Document *)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save;
-(Document *)newDocument:(NSString *)text displayName:(NSString *)displayName tableName:(NSString *)tableName tableset:(NSURL *)tableset display:(bool)display;

@end
