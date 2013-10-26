//
//  DocumentController.h
//  MaciASL
//
//  Created by PHPdev32 on 10/14/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface DocumentController : NSDocumentController

@property (assign) IBOutlet NSWindow *tableView;

-(IBAction)finishTableset:(id)sender;

-(id)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save;
-(id)newDocument:(NSString *)text withName:(NSString *)name display:(bool)display;

@end
