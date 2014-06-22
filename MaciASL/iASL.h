//
//  iASL.h
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface iASLDecompilationResult : NSObject

@property (readonly) NSError *error;
@property (readonly) NSString *string;

@end

@interface iASLCompilationResult : iASLDecompilationResult

@property (readonly) NSArray *notices;
@property (readonly) NSURL *url;

@end

typedef NS_ENUM(NSUInteger, iASLNoticeType) {
    iASLNoticeTypeWarning,
    iASLNoticeTypeWarning2,
    iASLNoticeTypeWarning3,
    iASLNoticeTypeError,
    iASLNoticeTypeRemark,
    iASLNoticeTypeOptimization
};

@interface Notice : NSObject

@property (readonly) iASLNoticeType type;
@property (readonly) NSUInteger line, code;
@property (readonly) NSString *message;

@end

@interface iASL : NSObject

extern NSURL *const kSystemTableset;

+(NSDictionary *)tableset;
+(NSArray *)deviceProperties;
+(NSString *)isInjected:(NSURL *)url;
+(NSURL *)wasInjected:(NSString *)table;
+(NSData *)fetchTable:(NSString *)table;
+(iASLDecompilationResult *)decompileAML:(NSData *)aml name:(NSString *)name tableset:(NSURL *)tableset;
+(iASLCompilationResult *)compileDSL:(NSString *)dsl name:(NSString *)name tableset:(NSURL *)tableset force:(bool)force;


@end

@interface TypeTransformer : NSValueTransformer

@end

@interface URLTask : NSObject

+(void)conditionalGet:(NSURL *)url toURL:(NSURL *)file perform:(void(^)(bool))handler;

@end
