//
//  SSDT.h
//  MaciASL
//
//  Created by PHPdev32 on 1/8/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface SSDTGen : NSObject

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *sourceView;
@property (strong) IBOutlet NSTextView *generatorView;
@property NSNumber *tdp;
@property NSNumber *mtf;
@property NSNumber *cpufrequency;
@property NSNumber *logicalcpus;
@property NSString *generator;

-(IBAction)show:(id)sender;
-(IBAction)chooseGenerator:(id)sender;
-(IBAction)reset:(id)sender;
-(IBAction)generate:(id)sender;

@end

@interface NSComparisonPredicate (MathAdditions)

+(NSComparisonPredicate *)parseExpression:(NSString *)expression;
-(NSNumber *)evaluateWithSubstitution:(NSDictionary *)substitutions;

@end