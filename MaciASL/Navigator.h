//
//  Navigator.h
//  MaciASL
//
//  Created by PHPdev32 on 9/28/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface NavObject : NSObject {
    @private
    NSRange _contentRange;
}

@property NSString *name;
@property NSRange range;

-(NSRange)contentRange:(NSString *)text;

@end

@interface Scope : NavObject

@property NSMutableArray *children;

+(id)create:(NSString *)name withRange:(NSRange)range;
-(NSMutableArray *)flat;
-(bool)isSelf:(NSRange)check;

@end

@interface DefinitionBlock : Scope

+(DefinitionBlock *)build:(NSString *)dsl;

@end

@interface Device : Scope
@end

@interface Processor : Device
@end

@interface Method : Scope
@end

@interface ThermalZone : Scope
@end

@interface NavTransformer : NSValueTransformer

+(Class)transformedValueClass;
+(BOOL)allowsReverseTransformation;
-(id)transformedValue:(id)value;

@end

@interface NavClassTransformer : NSValueTransformer

+(Class)transformedValueClass;
+(BOOL)allowsReverseTransformation;
-(id)transformedValue:(id)value;

@end