//
//  SSDT.m
//  MaciASL
//
//  Created by PHPdev32 on 1/8/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "SSDT.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import "AppDelegate.h"
#import "Source.h"

@implementation SSDTGen
static SSDTGen *sharedSSDT;

@synthesize tdp;
@synthesize mtf;
@synthesize cpufrequency;
@synthesize logicalcpus;
@synthesize generator;
@synthesize window;
@synthesize sourceView;
@synthesize generatorView;

#pragma mark Class
-(id)init{
    if (sharedSSDT) return sharedSSDT;
    self = [super init];
    if (self) {
        LoadNib(@"SSDT", self);
        [self reset:self];
        [SourceList.sharedList addObserver:self forKeyPath:@"providers" options:0 context:nil];
        sharedSSDT = self;
    }
    return self;
}
-(void)loadGenerator:(NSDictionary *)dict{
    assignWithNotice(self, generator, [dict objectForKey:@"response"])
    [window makeFirstResponder:generatorView];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self performSelector:@selector(expandTree) withObject:nil afterDelay:0];
}
-(void)expandTree{
    [sourceView expandItem:nil expandChildren:true];
}

#pragma mark GUI
-(IBAction)show:(id)sender{
    bool first = ([window windowNumber] == -1);
    [window makeKeyAndOrderFront:sender];
    if (first)
        [[NSApp delegate] changeFont:nil];
    SplitView([[window.contentView subviews] objectAtIndex:0]);
    SplitView((NSSplitView *)generatorView.superview.superview.superview.superview);
    [self expandTree];
}
-(IBAction)chooseGenerator:(id)sender{
    if ([sender selectedRow] == -1 || ![[[sender itemAtRow:[sender selectedRow]] representedObject] isMemberOfClass:[SourcePatch class]])
        return;
    NSURL *url = [[[sender itemAtRow:[sender selectedRow]] representedObject] url];
    if (![url.standardizedURL isEqualTo:url]) {
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kURLStandardError userInfo:@{NSLocalizedDescriptionKey:@"URL Standardization Error", NSLocalizedRecoverySuggestionErrorKey:@"The URL provided could not be standardized and may be incorrect."}]);
        return;
    }
    AsynchFetch(url.standardizedURL, @selector(loadGenerator:), self, nil);
    [sender deselectAll:sender];
}
-(IBAction)reset:(id)sender{
    assignWithNotice(self, tdp, nil)
    assignWithNotice(self, mtf, nil)
    NSInteger logical = 0;
    NSInteger freq = 0;
    NSUInteger size = 4;
    sysctlbyname("hw.logicalcpu", &logical, &size, NULL, 0);
    size = 8;
    sysctlbyname("hw.cpufrequency", &freq, &size, NULL, 0);
    assignWithNotice(self, logicalcpus, @(logical))
    assignWithNotice(self, cpufrequency, @(freq/1E6))
    assignWithNotice(self, generator, @"")
}
-(IBAction)generate:(id)sender {
    if (!mtf || !logicalcpus || !cpufrequency || !tdp) {
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kNULLSSDTError userInfo:@{NSLocalizedDescriptionKey:@"Missing Value", NSLocalizedRecoverySuggestionErrorKey:@"One or more values are empty"}]);
        return;
    }
    if (cpufrequency.integerValue > mtf.integerValue) {
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kFreqRangeError userInfo:@{NSLocalizedDescriptionKey:@"Incorrect Range", NSLocalizedRecoverySuggestionErrorKey:@"CPU Frequency must be less than Max Turbo Frequency"}]);
        return;
    }
    [window performClose:sender];
    NSInteger maxFreq = mtf.integerValue;
    NSInteger logicalCpus = logicalcpus.integerValue;
    NSInteger freq = cpufrequency.integerValue;
    NSInteger thermal = tdp.integerValue;
    NSUInteger minFreq = 0;
    NSComparisonPredicate *powerSlope;
    NSDictionary *fields = [Patch fields:generator];
    if ([fields objectForKey:@"SSDT"]) {
        if ([[fields objectForKey:@"SSDT"] objectForKey:@"MinFreq"] && !(minFreq = [[[fields objectForKey:@"SSDT"] objectForKey:@"MinFreq"] integerValue]))
            ModalError([NSError errorWithDomain:kMaciASLDomain code:kNSComparisonPredicateError userInfo:@{NSLocalizedDescriptionKey:@"Textual Math Parse Failure", NSLocalizedRecoverySuggestionErrorKey:@"The textual math entered could not be parsed by the NSPredicate parser, discarding it."}]);
        if ([[fields objectForKey:@"SSDT"] objectForKey:@"PowerSlope"])
            powerSlope = [NSComparisonPredicate parseExpression:[[fields objectForKey:@"SSDT"] objectForKey:@"PowerSlope"]];
    }
    if (!minFreq) minFreq = 1600;
    if (!powerSlope) powerSlope = [NSComparisonPredicate parseExpression:@"max({min({floor(($freq-1)/$maxFreq),1}),0})*floor(($ratio / $maxRatio) * (((1.1 - (($maxRatio - $ratio) * 0.00625)) / 1.1) ** 2) * $tdp)+max({min({floor($maxFreq/$freq),1}),0})*$tdp"];
    NSInteger turboFreq = (maxFreq - freq) / 100;
    NSInteger maxRatio = maxFreq / 100;
    NSInteger pkgs = (maxFreq - minFreq + 100) / 100;
    NSInteger cpus = 0;
    NSMutableString *ssdt = [NSMutableString stringWithFormat:@"// Translated from RevoGirl's ssdtPRGen script v0.9\n// Generated with %ldW TDP, %ldMHz Max Turbo Freq\n", thermal, maxFreq];
    [ssdt appendString:@"DefinitionBlock (\"SSDT.aml\", \"SSDT\", 1, \"APPLE \", \"CpuPm\", 0x00001000)\n{\n"];
    while (cpus < logicalCpus)
        [ssdt appendFormat:@"    External (\\_PR_.CPU%lX, DeviceObj)\n", cpus++];
    [ssdt appendFormat:@"\n    Scope (_PR.CPU0)\n    {\n        Name (APSN, 0x%02lX)\n        Name (APSS, Package (0x%02lX)\n        {\n", turboFreq, pkgs];
    NSMutableDictionary *variables = [@{@"maxRatio":@((double)maxRatio),  @"freq":@((double)freq), @"tdp":@((double)thermal*1000)} mutableCopy];
    while (pkgs-- > 0) {
        [ssdt appendFormat:@"\n            Package (0x06)\n            {\n                0x%08lX,\n", maxFreq];
        NSInteger ratio = maxFreq / 100;
        [variables setObject:@((double)ratio) forKey:@"ratio"];
        [variables setObject:@((double)maxFreq) forKey:@"maxFreq"];
        [ssdt appendFormat:@"                0x%08lX,\n                0x0000000A,\n                0x0000000A,\n                0x%06lX00,\n                0x%06lX00\n", [[powerSlope evaluateWithSubstitution:variables] integerValue], ratio, ratio];
        maxFreq -= 100;
        [ssdt appendString:pkgs?@"            },\n":@"            }\n"];
    }
    [ssdt appendString:@"        })\n\n        Method (ACST, 0, NotSerialized)\n        {\n            Return (Package (0x06)\n            {\n                One,\n                0x04,\n                Package (0x04)\n                {\n                    ResourceTemplate ()\n                    {\n                        Register (FFixedHW,\n                            0x01,               // Bit Width\n                            0x02,               // Bit Offset\n                            0x0000000000000000, // Address\n                            0x01,               // Access Size\n                            )\n                    },\n\n                    One,\n                    0x03,\n                    0x03E8\n                },\n\n                Package (0x04)\n                {\n                    ResourceTemplate ()\n                    {\n                        Register (FFixedHW,\n                            0x01,               // Bit Width\n                            0x02,               // Bit Offset\n                            0x0000000000000010, // Address\n                            0x03,               // Access Size\n                            )\n                    },\n\n                    0x03,\n                    0xCD,\n                    0x01F4\n                },\n\n                Package (0x04)\n                {\n                    ResourceTemplate ()\n                    {\n                        Register (FFixedHW,\n                            0x01,               // Bit Width\n                            0x02,               // Bit Offset\n                            0x0000000000000020, // Address\n                            0x03,               // Access Size\n                            )\n                    },\n\n                    0x06,\n                    0xF5,\n                    0x015E\n                },\n\n                Package (0x04)\n                {\n                    ResourceTemplate ()\n                    {\n                        Register (FFixedHW,\n                            0x01,               // Bit Width\n                            0x02,               // Bit Offset\n                            0x0000000000000030, // Address\n                            0x03,               // Access Size\n                            )\n                    },\n\n                    0x07,\n                    0xF5,\n                    0xC8\n                }\n            })\n        }\n    }\n"];
    cpus = 1;
    while (cpus < logicalCpus)
        [ssdt appendFormat:@"\n    Scope (\\_PR.CPU%lX)\n    {\n        Method (APSS, 0, NotSerialized)\n        {\n            Return (\\_PR.CPU0.APSS)\n        }\n    }\n", cpus++];
    [ssdt appendString:@"}\n"];
    Document *doc = [[NSApp delegate] newDocument:ssdt withName:@"Generated SSDT"];
    if (doc) [doc quickPatch:generator];
}

@end

@implementation NSComparisonPredicate (MathAdditions)

+(NSComparisonPredicate *)parseExpression:(NSString *)expression{
    @try {
        return (NSComparisonPredicate *)[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(%@)=0", expression]];
    }
    @catch (NSException *ex) { return nil; }
}
-(NSNumber *)evaluateWithSubstitution:(NSDictionary *)substitutions{
    @try {
        return [[(NSComparisonPredicate *)[self predicateWithSubstitutionVariables:substitutions] leftExpression] expressionValueWithObject:nil context:nil];
    }
    @catch (NSException *ex) { return nil; }
}

@end
