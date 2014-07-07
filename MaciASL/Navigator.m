//
//  Navigator.m
//  MaciASL
//
//  Created by PHPdev32 on 9/28/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Navigator_Scopes.h"

@implementation NavObject {
    @private
    NSRange _contentRange;
}

static NSSet *containerClasses;
static NSRegularExpression *conts;
static NSCharacterSet *braces;
static NSCharacterSet *unset;

+(void)load {
    NSArray *containers = @[/*@"Alias", @"Buffer",*/ @"Device", @"DefinitionBlock", /*@"Function",*/ @"Method", /*@"Name", @"Package", @"PowerResource",*/ @"Processor", /*@"RawDataBuffer",*/ @"Scope", @"ThermalZone"];
    NSMutableSet *classes = [NSMutableSet setWithCapacity:containers.count];
    for (NSString *cls in containers)
        [classes addObject:NSClassFromString(cls)];
    containerClasses = [classes copy];
    conts = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(%@)\\s*\\(\\s*([\\^\\\\]*[A-Z0-9_.]+)\\s*[),]", [containers componentsJoinedByString:@"|"]] options:0 error:nil];
    braces = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
    unset = [[NSCharacterSet characterSetWithCharactersInString:@" \n"] invertedSet];
}

-(instancetype)initWithName:(NSString *)name range:(NSRange)range {
    self = [super init];
    if (self) {
        _name = name;
        _range = range;
    }
    return self;
}

-(void)setRange:(NSRange)range {
    _range = range;
}

-(NSRange)contentRange:(NSString *)text {
    if (NSMaxRange(_contentRange)) return _contentRange;
    NSRange temp = [text rangeOfString:@"{" options:0 range:_range];
    temp = NSMakeRange(temp.location+1, NSMaxRange(_range)-temp.location-2);
    _contentRange = ([text rangeOfCharacterFromSet:unset options:0 range:temp].location == NSNotFound)
    ? NSMakeRange(temp.location, 0)
    : NSUnionRange([text rangeOfCharacterFromSet:unset options:0 range:temp], [text rangeOfCharacterFromSet:unset options:NSBackwardsSearch range:temp]);
    return _contentRange;
}

-(NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ \"%@\" (%ld, %ld)", NSStringFromClass(self.class), _name, _range.location, _range.length];
}

@end

@implementation Scope {
    @protected
    NSMutableArray *_children;
}

#pragma mark NSObject Lifecycle
-(instancetype)initWithName:(NSString *)name range:(NSRange)range {
    self = [super initWithName:name range:range];
    if (self)
        _children = [NSMutableArray array];
    return self;
}

-(void)addChildrenObject:(NavObject *)object {
    [_children addObject:object];
}

-(NSString *)debugDescription {
    return [[super debugDescription] stringByAppendingFormat:_children.count ? @" {\n%@\n}" : @" {%@}", [[_children valueForKey:@"debugDescription"] componentsJoinedByString:@"\n"]];
}

-(bool)isSelf:(NSRange)check {
    for (NavObject *child in _children) {
        if (NSMaxRange(check) < child.range.location)
            return true;
        if (NSIntersectionRange(check, child.range).location)
            return false;
    }
    return true;
}

#pragma mark Readonly Properties
-(NSArray *)flat {
    NSMutableArray *temp = [NSMutableArray arrayWithObject:self];
    for (Scope *child in _children)
        [temp addObjectsFromArray:child.flat];
    return [temp copy];
}

-(NSArray *)children {
    return [_children copy];
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

+(DefinitionBlock *)emptyBlock {
    return [[DefinitionBlock alloc] initWithName:@"<Empty>" range:NSMakeRange(0, 0)];
}

+(DefinitionBlock *)build:(NSString *)dsl{
    NSString *test;
    NSScanner *scan = [NSScanner scannerWithString:dsl];
    [scan scanUpToString:@"DefinitionBlock" intoString:NULL];
    if ([scan isAtEnd]) return nil;
    [scan scanUpToString:@"," intoString:NULL];
    [scan scanUpToString:@"\"" intoString:NULL];
    [scan scanString:@"\"" intoString:NULL];
    [scan scanUpToString:@"\"" intoString:&test];
    DefinitionBlock *root = [[DefinitionBlock alloc] initWithName:test range:NSMakeRange(0, dsl.length)];
    NSMutableArray *path = [NSMutableArray arrayWithObject:root];
    Scope *container = (Scope *)path.lastObject;
    NSUInteger depth = 1;
    [scan scanUpToCharactersFromSet:braces intoString:&test];
    [scan scanCharactersFromSet:braces intoString:NULL];
    while (![scan isAtEnd]) {
        __block bool found = false;
        [scan scanUpToCharactersFromSet:braces intoString:&test];
        [conts enumerateMatchesInString:test options:0 range:NSMakeRange(0, test.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
            found = true;
            [container addChildrenObject:[[NSClassFromString([test substringWithRange:[result rangeAtIndex:1]]) alloc] initWithName:[test substringWithRange:[result rangeAtIndex:2]] range:NSMakeRange(result.range.location+(scan.scanLocation-test.length),result.range.length)]];
        }];
        [scan scanCharactersFromSet:braces intoString:&test];
        Scope *child = container.children.lastObject;
        if ([test isEqualToString:@"{}"]) {
            if (found && [containerClasses containsObject:child.class])
                child.range = NSMakeRange(child.range.location, scan.scanLocation - child.range.location);
        }
        else if ([test isEqualToString:@"{"]) {
            depth++;
            if (found && [containerClasses containsObject:child.class]){
                [path addObject:child];
                container = child;
            }
            else
                [path addObject:NSNull.null];
        }
        else if ([test characterAtIndex:0] == '}') {
            NSUInteger i = 0;
            while (i < test.length) {
                if ([test characterAtIndex:i++] != '}') continue;
                if (depth-- == path.count){
                    if ((id)(child = path.lastObject) != NSNull.null)
                        child.range = NSMakeRange(child.range.location, scan.scanLocation - child.range.location);
                    [path removeLastObject];
                    if (path.lastObject == NSNull.null) {
                        NSUInteger item = path.count - 2;
                        while ((id)(container = child = [path objectAtIndex:item]) == NSNull.null)
                            item--;
                    }
                    else
                        container = child = path.lastObject;
                }
            }
        }
    }
    return root;
}

-(DefinitionBlock *)filteredWithString:(NSString *)filter {
    NSMutableArray *temp = [self.flat mutableCopy];
    [temp filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings){
        return [[evaluatedObject name] rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound;
    }]];
    if (temp.count && [temp objectAtIndex:0] == self)
        [temp removeObjectAtIndex:0];
    return [[DefinitionBlock alloc] initWithName:self.name range:self.range flatChildren:temp];
}

-(instancetype)initWithName:(NSString *)name range:(NSRange)range flatChildren:(NSArray *)children {
    self = [super initWithName:name range:range];
    if (self)
        [_children addObjectsFromArray:children];
    return self;
}

@end

@interface NavTransformer : NSValueTransformer

@end

@implementation NavTransformer

static NSFont *font;
static NSAttributedString *separator;
static NSDictionary *attr;

+(void)load {
    font = [NSFont systemFontOfSize:12.0];
    separator = [[NSAttributedString alloc] initWithString:@" \u2023 " attributes:@{NSForegroundColorAttributeName:NSColor.grayColor, NSFontAttributeName:font}];
    attr = @{NSFontAttributeName:font};
}

+(Class)transformedValueClass {
    return [NSAttributedString class];
}

+(BOOL)allowsReverseTransformation {
    return false;
}

-(id)transformedValue:(id)value{
    if (![value count]) return nil;
    value = [value objectAtIndex:0];
    NSMutableAttributedString *names = [[NSMutableAttributedString alloc] initWithString:[[(NSTreeNode *)value representedObject] name] attributes:attr];
    while ((value = [value parentNode]) && [[(NSTreeNode *)value representedObject] isKindOfClass:[NavObject class]]) {
        [names insertAttributedString:separator atIndex:0];
        [names insertAttributedString:[[NSAttributedString alloc] initWithString:[[(NSTreeNode *)value representedObject] name] attributes:attr] atIndex:0];
    }
    return [names copy];
}

@end

@interface NavClassTransformer : NSValueTransformer

@end

@implementation NavClassTransformer

static NSString *prefix = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sidebar";

+(Class)transformedValueClass {
    return [NSImage class];
}

+(BOOL)allowsReverseTransformation {
    return false;
}

-(id)transformedValue:(id)value {
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
