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

-(instancetype)initWithName:(NSString *)name URL:(NSURL *)url children:(NSDictionary *)children {
    NSAssert(self.class == SourceProvider.class || !children, @"Bad initialization");
    self = [super init];
    if (self) {
        _name = name;
        _url = url;
        _children = children;
    }
    return self;
}

-(instancetype)initWithName:(NSString *)name URL:(NSURL *)url {
    return [self initWithName:name URL:url children:nil];
}

@end

@implementation SourceProvider

@end

@implementation SourceList {
    @private
    NSMutableDictionary *_archive;
    NSMutableArray *_providers;
    SCNetworkReachabilityRef _reachability;
}

static SourceList *sharedList;

+(SourceList *)sharedList {
    return sharedList ?: [SourceList new];
}

#pragma mark NSObject Lifecycle
-(instancetype)init {
    if (sharedList) return sharedList;
    self = [super init];
    if (self) {
        _archive = [NSMutableDictionary dictionary];
        _providers = [NSMutableArray array];
        _queue = dispatch_queue_create("net.sourceforge.maciasl.sourcelist", DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_context(_queue, (void *)true);
        _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "sourceforge.net");
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(_reachability, &flags);
        [self reachabilityDidChange:flags];
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, CFRetain, CFRelease, CFCopyDescription};
        SCNetworkReachabilitySetCallback(_reachability, ReachabilityDidChange, &context);
        SCNetworkReachabilitySetDispatchQueue(_reachability, dispatch_get_main_queue());
        [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"sources" options:0 context:nil];
        sharedList = self;
    }
    return self;
}

-(void)dealloc {
    if (_providers)
        [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"sources"];
    if (_reachability) {
        SCNetworkReachabilitySetDispatchQueue(_reachability, NULL);
        CFRelease(_reachability);
    }
}

-(void)UTF8StringWithContentsOfURL:(NSURL *)url completionHandler:(void (^)(NSString *))completionHandler {
    dispatch_async(_queue, ^{
        NSURLResponse *response;
        NSError *err;
        NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60] returningResponse:&response error:&err];
        if ([response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse *)response statusCode] != 200)
            ModalError(err ?: [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:@{NSLocalizedDescriptionKey:@"File Fetch Error",NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"URL '%@' said '%@'",url,[NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse *)response statusCode]]]}]);
        else
            dispatch_async(dispatch_get_main_queue(), ^{ completionHandler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]); });
    });
}

#pragma mark SCNetworkReachability
void ReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    [(__bridge SourceList *)info reachabilityDidChange:flags];
}

-(void)reachabilityDidChange:(SCNetworkReachabilityFlags)flags {
    bool active = (bool)dispatch_get_context(_queue), reachable = flags & kSCNetworkFlagsReachable;
    if (!active && reachable)
        dispatch_resume(_queue);
    else if (active && !reachable)
        dispatch_suspend(_queue);
    dispatch_set_context(_queue, (void *)reachable);
}

#pragma mark Observation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSArray *oldNames = [_providers valueForKey:@"name"];
    NSArray *new = [NSUserDefaults.standardUserDefaults objectForKey:@"sources"];
    for (NSDictionary *provider in new) {
        if (![_archive objectForKey:[provider objectForKey:@"url"]]) {
            NSString *name = [provider objectForKey:@"name"], *url = [provider objectForKey:@"url"];
            if (![name isKindOfClass:[NSString class]] || ![url isKindOfClass:[NSString class]])
                continue;
            NSURL *realURL = [NSURL URLWithString:url];
            [self UTF8StringWithContentsOfURL:[realURL URLByAppendingPathComponent:@".maciasl"] completionHandler:^(NSString *response) {
                NSMutableArray *dsdt = [NSMutableArray array];
                NSMutableArray *ssdt = [NSMutableArray array];
                for(NSString *line in [response componentsSeparatedByString:@"\n"]) {
                    if ([line rangeOfString:@"\t"].location == NSNotFound) continue;
                    NSArray *temp = [line componentsSeparatedByString:@"\t"];
                    SourcePatch *p = [[SourcePatch alloc] initWithName:[temp objectAtIndex:0] URL:[realURL URLByAppendingPathComponent:temp.lastObject]];
                    if (temp.count == 3 && [[temp objectAtIndex:1] isEqualToString:@"SSDT"])
                        [ssdt addObject:p];
                    else
                        [dsdt addObject:p];
                }
                if (dsdt.count + ssdt.count == 0) return;
                SourceProvider *temp = [[SourceProvider alloc] initWithName:name URL:realURL children:@{@"DSDT":[dsdt copy], @"SSDT":[ssdt copy]}];
                [self->_archive setObject:temp forKey:url];
                muteWithNotice(self, providers, [self->_providers addObject:temp])
            }];
        }
        else if (![oldNames containsObject:[provider objectForKey:@"name"]]) {
            muteWithNotice(self, providers, [_providers addObject:[_archive objectForKey:[provider objectForKey:@"url"]]])
        }
    }
    NSArray *newNames = [new valueForKey:@"name"];
    for (SourceProvider *provider in [_providers copy])
        if (![newNames containsObject:provider.name]) {
            muteWithNotice(self, providers, [_providers removeObject:provider])
        }
}

#pragma mark Readonly Properties
-(NSArray *)providers {
    return [_providers copy];
}

@end

@implementation SrcClassTransformer
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
    if ([value class] == [SourcePatch class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"GenericFile.icns"]];
    else if ([value class] == [SourceProvider class])
        return [image initByReferencingFile:[prefix stringByAppendingString:@"GenericFolder.icns"]];
    return image;
}

@end
