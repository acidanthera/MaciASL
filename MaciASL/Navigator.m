//
//  Navigator.m
//  MaciASL
//
//  Created by PHPdev32 on 9/28/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Navigator.h"

@implementation NavObject
static NSArray *containers;
static NSRegularExpression *conts;
static NSCharacterSet *braces;
static NSCharacterSet *unset;

+(void)initialize{
    containers = @[/*@"Alias", @"Buffer",*/ @"Device", @"DefinitionBlock", /*@"Function",*/ @"Method", /*@"Name", @"Package", @"PowerResource",*/ @"Processor", /*@"RawDataBuffer",*/ @"Scope", @"ThermalZone"];
    conts = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(%@)\\s*\\(\\s*([^),]{0,4})\\s*[),]", [containers componentsJoinedByString:@"|"]] options:0 error:nil];
    braces = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
    unset = [[NSCharacterSet characterSetWithCharactersInString:@" \n"] invertedSet];
}

@synthesize name;
@synthesize range;

-(NSRange)contentRange:(NSString *)text{
    if (NSMaxRange(_contentRange)) return _contentRange;
    NSRange temp = [text rangeOfString:@"{" options:0 range:range];
    temp = NSMakeRange(temp.location+1, NSMaxRange(range)-temp.location-2);
    _contentRange = ([text rangeOfCharacterFromSet:unset options:0 range:temp].location == NSNotFound)
    ? NSMakeRange(temp.location, 0)
    : NSUnionRange([text rangeOfCharacterFromSet:unset options:0 range:temp], [text rangeOfCharacterFromSet:unset options:NSBackwardsSearch range:temp]);
    return _contentRange;
}

@end

@implementation Scope
@synthesize children;
+(id)create:(NSString *)name withRange:(NSRange)range{
    Scope *temp = [self new];
    temp.name = name;
    temp.range = range;
    temp.children = [NSMutableArray array];
    return temp;
}
-(bool)isSelf:(NSRange)check{
    for (NavObject *child in children) {
        if (NSMaxRange(check) < child.range.location)
            return true;
        if (NSIntersectionRange(check, child.range).location)
            return false;
    }
    return true;
}
-(NSMutableArray *)flat{
    NSMutableArray *temp = [NSMutableArray arrayWithObject:self];
    for (Scope *child in children)
        [temp addObjectsFromArray:child.flat];
    return temp;
}
@end
@implementation Device
@end
@implementation Processor
@end
@implementation ThermalZone
@end
@implementation Method
@end

@implementation DefinitionBlock

+(DefinitionBlock *)build:(NSString *)dsl{
    NSString *test;
    NSScanner *scan = [NSScanner scannerWithString:dsl];
    [scan scanUpToString:@"DefinitionBlock" intoString:NULL];
    if ([scan isAtEnd]) return nil;
    [scan scanUpToString:@"," intoString:NULL];
    [scan scanUpToString:@"\"" intoString:NULL];
    [scan scanString:@"\"" intoString:NULL];
    [scan scanUpToString:@"\"" intoString:&test];
    DefinitionBlock *root = [DefinitionBlock create:test withRange:NSMakeRange(0, dsl.length)];
    NSMutableArray *path = [NSMutableArray arrayWithObject:root];
    __block NSMutableArray *children = [(Scope *)path.lastObject children];
    NSUInteger depth = 1;
    [scan scanUpToCharactersFromSet:braces intoString:&test];
    [scan scanCharactersFromSet:braces intoString:NULL];
    while (![scan isAtEnd]) {
        __block bool found = false;
        [scan scanUpToCharactersFromSet:braces intoString:&test];
        [conts enumerateMatchesInString:test options:0 range:NSMakeRange(0, test.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
            found = true;
            [children addObject:[NSClassFromString([test substringWithRange:[result rangeAtIndex:1]]) create:[test substringWithRange:[result rangeAtIndex:2]] withRange:NSMakeRange(result.range.location+(scan.scanLocation-test.length),result.range.length)]];
        }];
        [scan scanCharactersFromSet:braces intoString:&test];
        Scope *child = children.lastObject;
        if ([test isEqualToString:@"{}"]) {
            if (found && [containers containsObject:NSStringFromClass(child.class)])
                child.range = NSMakeRange(child.range.location,scan.scanLocation - child.range.location);
        }
        else if ([test isEqualToString:@"{"]) {
            depth++;
            if (found && [containers containsObject:NSStringFromClass(child.class)]){
                [path addObject:child];
                children = child.children;
            }
        }
        else if ([test hasPrefix:@"}"]) {
            NSUInteger i = 0;
            while (i < test.length) {
                if ([test characterAtIndex:i++] != '}') continue;
                if (depth-- == path.count){
                    child = path.lastObject;
                    child.range = NSMakeRange(child.range.location,scan.scanLocation - child.range.location);
                    [path removeLastObject];
                    child = path.lastObject;
                    children = child.children;
                }
            }
        }
    }
    return root;
}

@end

@implementation NavTransformer
static NSFont *font;
static NSAttributedString *separator;
static NSDictionary *attr;

+(void)initialize{
    font = [NSFont systemFontOfSize:12.0];
    separator = [[NSAttributedString alloc] initWithString:@" \u2023 " attributes:@{NSForegroundColorAttributeName:[NSColor grayColor], NSFontAttributeName:font}];
    attr = @{NSFontAttributeName:font};
}
+(Class)transformedValueClass{
    return [NSAttributedString class];
}
+(BOOL)allowsReverseTransformation{
    return false;
}
-(id)transformedValue:(id)value{
    if (![value count]) return nil;
    value = [value objectAtIndex:0];
    NSMutableAttributedString *names = [[NSMutableAttributedString alloc] initWithString:[[value representedObject] name] attributes:attr];
    while ((value = [value parentNode]) && [[value representedObject] isKindOfClass:[NavObject class]]) {
        [names insertAttributedString:separator atIndex:0];
        [names insertAttributedString:[[NSAttributedString alloc] initWithString:[[value representedObject] name] attributes:attr] atIndex:0];
    }
    return [names copy];
}

@end

@implementation NavClassTransformer
static NSString *prefix = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sidebar";

+(Class)transformedValueClass{
    return [NSImage class];
}
+(BOOL)allowsReverseTransformation{
    return false;
}
-(id)transformedValue:(id)value{
    NSImage *image = [NSImage alloc];
    image.template = true;
    if ([value  class] == [DefinitionBlock class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"HomeFolder.icns"]];
    else if ([value  class] == [Scope class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"GenericFolder.icns"]];
    else if ([value  class] == [Method class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"ApplicationsFolder.icns"]];
    else if ([value  class] == [Device class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"ExternalDisk.icns"]];
    else if ([value  class] == [Processor class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"MacPro.icns"]];
    else if ([value  class] == [ThermalZone class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"BurnFolder.icns"]];
    return image;
}

@end