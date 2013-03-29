//
//  Source.m
//  MaciASL
//
//  Created by PHPdev32 on 10/1/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Source.h"

@implementation SourcePatch

@synthesize name;
@synthesize url;
@synthesize children;

+(SourcePatch *)create:(NSString *)name withURL:(NSURL *)url{
    SourcePatch *temp = [SourcePatch new];
    temp.name = name;
    temp.url = url;
    return temp;
}

@end

@implementation SourceProvider

+(SourceProvider *)create:(NSString *)name withURL:(NSURL *)url andChildren:(NSDictionary *)children{
    SourceProvider *temp = [SourceProvider new];
    temp.name = name;
    temp.url = url;
    temp.children = children;
    return temp;
}

@end

@implementation SourceList

static SourceList *sharedList;

@synthesize archive;
@synthesize providers;

+(SourceList *)sharedList{
    if (!sharedList) return [SourceList new];
    return sharedList;
}

-(id)init{
    if (sharedList) return sharedList;
    self = [super init];
    if (self) {
        self.archive = [NSMutableDictionary dictionary];
        self.providers = [NSMutableArray array];
        [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"sources" options:0 context:nil];
        [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
        sharedList = self;
    }
    return self;
}
-(void)dealloc{
    if (providers)
        [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"sources"];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSArray *oldNames = [providers valueForKey:@"name"];
    NSArray *new = [NSUserDefaults.standardUserDefaults objectForKey:@"sources"];
    for (NSDictionary *provider in new) {
        if (![archive objectForKey:[provider objectForKey:@"url"]])
            [self fetchProvider:[provider objectForKey:@"name"] withURL:[provider objectForKey:@"url"]];
        else if (![oldNames containsObject:[provider objectForKey:@"name"]]) {
            muteWithNotice(self, providers, [providers addObject:[archive objectForKey:[provider objectForKey:@"url"]]])
        }
    }
    NSArray *newNames = [new valueForKey:@"name"];
    for (SourceProvider *provider in providers)
        if (![newNames containsObject:provider.name]) {
            muteWithNotice(self, providers, [providers removeObject:provider])
        }
}
-(void)fetchProvider:(NSString *)name withURL:(NSString *)url{
    if (!name || ![name isKindOfClass:[NSString class]] || !url || ![url isKindOfClass:[NSString class]]) return;
    NSURL *realURL = [NSURL URLWithString:url];
    AsynchFetch([realURL URLByAppendingPathComponent:@".maciasl"], @selector(buildProvider:), self, @{@"name":name, @"url":url, @"realURL":realURL});
}
-(void)buildProvider:(NSDictionary *)dict{
    NSString *list = [dict objectForKey:@"response"];
    NSString *name = [[dict objectForKey:@"hold"] objectForKey:@"name"];
    NSString *url = [[dict objectForKey:@"hold"] objectForKey:@"url"];
    NSURL *realURL = [[dict objectForKey:@"hold"] objectForKey:@"realURL"];
    NSMutableArray *dsdt = [NSMutableArray array];
    NSMutableArray *ssdt = [NSMutableArray array];
    for(NSString *line in [list componentsSeparatedByString:@"\n"]) {
        if ([line rangeOfString:@"\t"].location == NSNotFound) continue;
        NSArray *temp = [line componentsSeparatedByString:@"\t"];
        if (temp.count == 3 && [[temp objectAtIndex:1] isEqualToString:@"SSDT"])
            [ssdt addObject:[SourcePatch create:[temp objectAtIndex:0] withURL:[realURL URLByAppendingPathComponent:temp.lastObject]]];
        else
            [dsdt addObject:[SourcePatch create:[temp objectAtIndex:0] withURL:[realURL URLByAppendingPathComponent:temp.lastObject]]];
    }
    if (dsdt.count + ssdt.count == 0) return;
    SourceProvider *temp = [SourceProvider create:name withURL:realURL andChildren:@{@"DSDT":[dsdt copy], @"SSDT":[ssdt copy]}];
    [archive setObject:temp forKey:url];
    muteWithNotice(self, providers, [providers addObject:temp])
}
@end

@implementation SrcClassTransformer
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
    if ([value class] == [SourcePatch class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"GenericFile.icns"]];
    else if ([value class] == [SourceProvider class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"GenericFolder.icns"]];
    return image;
}

@end
