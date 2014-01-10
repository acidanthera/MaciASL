//
//  Source.m
//  MaciASL
//
//  Created by PHPdev32 on 10/1/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Source.h"
#import <SystemConfiguration/SystemConfiguration.h>

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

@implementation SourceList {
    @private
    SCNetworkReachabilityRef _reachability;
}

static SourceList *sharedList;

@synthesize archive;
@synthesize providers;

void ReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    [(__bridge SourceList *)info reachabilityDidChange:flags];
}

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
        _queue = dispatch_queue_create("SourceList", DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_context(_queue, (void *)true);
        _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "sourceforge.net");
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(_reachability, &flags);
        [self reachabilityDidChange:flags];
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, CFRetain, CFRelease, CFCopyDescription};
        SCNetworkReachabilitySetCallback(_reachability, ReachabilityDidChange, &context);
        SCNetworkReachabilitySetDispatchQueue(_reachability, dispatch_get_main_queue());
        [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"sources" options:NSKeyValueObservingOptionInitial context:nil];
        sharedList = self;
    }
    return self;
}
-(void)reachabilityDidChange:(SCNetworkReachabilityFlags)flags {
    bool active = (bool)dispatch_get_context(_queue), reachable = flags & kSCNetworkFlagsReachable;
    if (!active && reachable)
        dispatch_resume(_queue);
    else if (active && !reachable)
        dispatch_suspend(_queue);
    dispatch_set_context(_queue, (void *)reachable);
}
-(void)dealloc{
    if (providers)
        [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"sources"];
    if (_reachability) {
        SCNetworkReachabilitySetDispatchQueue(_reachability, NULL);
        CFRelease(_reachability);
    }
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSArray *oldNames = [providers valueForKey:@"name"];
    NSArray *new = [NSUserDefaults.standardUserDefaults objectForKey:@"sources"];
    for (NSDictionary *provider in new) {
        if (![archive objectForKey:[provider objectForKey:@"url"]]) {
            NSString *name = [provider objectForKey:@"name"], *url = [provider objectForKey:@"url"];
            if (![name isKindOfClass:[NSString class]] || ![url isKindOfClass:[NSString class]])
                continue;
            NSURL *realURL = [NSURL URLWithString:url];
            AsynchB([realURL URLByAppendingPathComponent:@".maciasl"], ^(NSString *response) {
                NSMutableArray *dsdt = [NSMutableArray array];
                NSMutableArray *ssdt = [NSMutableArray array];
                for(NSString *line in [response componentsSeparatedByString:@"\n"]) {
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
            }, _queue);
        }
        else if (![oldNames containsObject:[provider objectForKey:@"name"]]) {
            muteWithNotice(self, providers, [providers addObject:[archive objectForKey:[provider objectForKey:@"url"]]])
        }
    }
    NSArray *newNames = [new valueForKey:@"name"];
    for (SourceProvider *provider in [providers copy])
        if (![newNames containsObject:provider.name]) {
            muteWithNotice(self, providers, [providers removeObject:provider])
        }
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
