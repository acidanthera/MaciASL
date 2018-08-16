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

/*! \brief Initializes the receiver (a repository) with the given parameters
 *
 * \param name The name of the repository
 * \param url The url of the repository
 * \param children The children of the repository, grouped by type (DSDT, SSDT, ...)
 * \returns The initialized receiver
 */
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

/*! \brief Initalizes the receiver (a patch) with the given parameters
 *
 * \param name The name of the patch
 * \param url The url of the patch
 * \returns The initialized receiver
 */
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
    bool _reach;
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
        _queue = [NSOperationQueue new];
        _queue.name = @"net.sourceforge.maciasl.sourcelist";
        _reach = true;
        _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "sourceforge.net");
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(_reachability, &flags);
        [self reachabilityDidChange:flags];
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, CFRetain, CFRelease, CFCopyDescription};
        SCNetworkReachabilitySetCallback(_reachability, ReachabilityDidChange, &context);
        SCNetworkReachabilitySetDispatchQueue(_reachability, dispatch_get_main_queue());
        [NSUserDefaults.standardUserDefaults addObserver:self
                                              forKeyPath:@"sources"
                                                 options:NSKeyValueObservingOptionInitial
                                                 context:nil];
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
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60] queue:_queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse *)response statusCode] != 200)
                ModalError(connectionError ?: [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:@{NSLocalizedDescriptionKey:@"File Fetch Error",NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"URL '%@' said '%@'",url,[NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse *)response statusCode]]]}]);
            else
                completionHandler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        });
    }];
}

#pragma mark SCNetworkReachability
void ReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    [(__bridge SourceList *)info reachabilityDidChange:flags];
}

/*! \brief Toggles the receiver's queue's suspension in response to network reachability
 *
 * \param flags The reachability flags returned by the callback
 */
-(void)reachabilityDidChange:(SCNetworkReachabilityFlags)flags {
    bool reachable = flags & kSCNetworkFlagsReachable;
    if (!_reach && reachable)
        _queue.suspended = false;
    else if (_reach && !reachable)
        _queue.suspended = true;
    _reach = reachable;
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
                    SourcePatch *p = [[SourcePatch alloc] initWithName:temp.firstObject URL:[realURL URLByAppendingPathComponent:temp.lastObject]];
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

static NSImage *patch, *provider;

+(void)load {
    NSBundle *ct = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];
    patch = [ct imageForResource:@"SidebarGenericFile"];
    provider = [ct imageForResource:@"SidebarGenericFolder"];
    patch.template = provider.template = true;
}

+(Class)transformedValueClass {
    return [NSImage class];
}

+(BOOL)allowsReverseTransformation {
    return false;
}

-(id)transformedValue:(id)value {
    if ([value class] == [SourcePatch class])
        return patch;
    else if ([value class] == [SourceProvider class])
        return provider;
    return nil;
}

@end
