//
//  iASL.h
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

enum noticeType {
    warning,
    warning2,
    warning3,
    error,
    remark,
    optimization
};

@interface iASL : NSObject

+(NSDictionary *)tableset;
+(NSArray *)deviceProperties;
+(NSString *)wasInjected:(NSString *)table;
+(NSData *)fetchTable:(NSString *)table;
+(NSDictionary *)decompile:(NSData *)aml withResolution:(NSString *)tableset;
+(NSDictionary *)compile:(NSString *)dsl force:(bool)force;
+(iASL *)create:(NSArray *)args withFile:(NSString *)file;
-(NSString *)stdOut;
-(NSString *)stdErr;

@property bool status;
@property NSTask *task;

@end

@interface Notice : NSObject

@property enum noticeType type;
@property NSUInteger line;
@property NSUInteger code;
@property NSString *message;

+(Notice *)create:(NSString *)entry;

@end

@interface TypeTransformer : NSValueTransformer

+(Class)transformedValueClass;
+(BOOL)allowsReverseTransformation;
-(id)transformedValue:(id)value;

@end

@interface NSTask (TaskAdditions)

@property SEL callback;
@property id listener;
@property (readonly) NSArray *stdOut;
@property (readonly) NSArray *stdErr;

+(NSTask *)create:(NSString *)path args:(NSArray *)arguments callback:(SEL)selector listener:(id)object;
-(void)launchAndWait;
-(void)read:(NSFileHandle *)handle;

@end

@interface NSConditionLock (NSTaskAdditions)

-(void)waitOn:(NSUInteger)condition;
-(void)increment;
-(void)decrement;

@end

@interface URLTask : NSObject

+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file;

@end