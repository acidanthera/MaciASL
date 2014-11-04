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
#import "Document.h"
#import "DocumentController.h"
#import "Patch.h"

@interface NSComparisonPredicate (MathAdditions)

@end

@implementation NSComparisonPredicate (MathAdditions)

/*! \brief Returns a ComparisonPredicate initialized with the given mathematical expression
 *
 * \param expression The expression which will be set equal to zero
 * \return The ComparisonPredicate, or nil, resulting from the parser
 */
+(NSComparisonPredicate *)parseExpression:(NSString *)expression {
    @try {
        return (NSComparisonPredicate *)[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(%@)=0", expression]];
    }
    @catch (NSException *ex) { return nil; }
}

/*! \brief Evaluates the receiver using the given substitutions
 *
 * \param substitutions A Dictionary of substitutions, Strings keyed to Numbers, to be used to evaluate the receiver
 * \return A Number, or nil, which is the result of the substitutions
 */
-(NSNumber *)evaluateWithSubstitution:(NSDictionary *)substitutions {
    @try {
        return [[(NSComparisonPredicate *)[self predicateWithSubstitutionVariables:substitutions] leftExpression] expressionValueWithObject:nil context:nil];
    }
    @catch (NSException *ex) { return nil; }
}

@end

@implementation SSDTGen {
    @private
    IBOutlet NSWindow *_window;
    IBOutlet NSOutlineView *_sourceView;
    IBOutlet NSTextView *_generatorView;
}

static SSDTGen *sharedGenerator;

+(SSDTGen *)sharedGenerator {
    return sharedGenerator ?: [SSDTGen new];
}

#pragma mark NSObject Lifecycle
-(instancetype)init {
    if (sharedGenerator) return sharedGenerator;
    self = [super init];
    if (self) {
        LoadNib(@"SSDT", self);
        [self resetGenerator:self];
        [SourceList.sharedList addObserver:self forKeyPath:@"providers" options:0 context:nil];
        sharedGenerator = self;
    }
    return self;
}

-(void)dealloc {
    [SourceList.sharedList removeObserver:self forKeyPath:@"providers" context:nil];
}

#pragma mark Observation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self performSelector:@selector(expandTree:) withObject:nil afterDelay:0];
}

/*! \brief Expands the receiver's OutlineView
 *
 * \param sender Not used
 */
-(IBAction)expandTree:(id)sender {
    [_sourceView expandItem:nil expandChildren:true];
}

/*! \brief Returns a String representation of the given CPU number
 *
 * \param cpu The number of the CPU
 * \returns A String in either hexadecimal or decimal, representing the CPU given
 */
-(NSString *)stringForCPU:(NSUInteger)cpu {
    return [_logicalcpus isGreaterThan:@16]
    ? [NSString stringWithFormat:@"C%lX0%lX", cpu/16, cpu%16]
    : [NSString stringWithFormat:@"CPU%lX", cpu];
}

#pragma mark Actions
/*! \brief Displays the window of the receiver
 *
 * \param sender Not used
 */
-(IBAction)show:(id)sender {
    bool first = ([_window windowNumber] == -1);
    [_window makeKeyAndOrderFront:sender];
    if (first)
        [(AppDelegate *)[(NSApplication *)NSApp delegate] changeFont:nil];
    SplitView([[_window.contentView subviews] objectAtIndex:0]);
    SplitView([[[[_window.contentView subviews] objectAtIndex:0] subviews] objectAtIndex:1]);
    [self expandTree:sender];
}

/*! \brief Called in response to a tree selection, to load the given generator
 *
 * \param sender The OutlineView which was clicked
 */
-(IBAction)chooseGenerator:(id)sender {
    if ([sender selectedRow] == -1 || ![[(NSTreeNode *)[sender itemAtRow:[sender selectedRow]] representedObject] isMemberOfClass:[SourcePatch class]])
        return;
    NSURL *url = [[(NSTreeNode *)[sender itemAtRow:[sender selectedRow]] representedObject] url];
    if (![url.standardizedURL isEqualTo:url]) {
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kURLStandardError userInfo:@{NSLocalizedDescriptionKey:@"URL Standardization Error", NSLocalizedRecoverySuggestionErrorKey:@"The URL provided could not be standardized and may be incorrect."}]);
        return;
    }
    [SourceList.sharedList UTF8StringWithContentsOfURL:url.standardizedURL completionHandler:^(NSString *response) {
        self.generator = response;
        [self->_window makeFirstResponder:self->_generatorView];
    }];
    [sender deselectAll:sender];
}

/*! \brief Reset's the receiver's view
 *
 * \param sender Not used
 */
-(IBAction)resetGenerator:(id)sender {
    self.tdp = nil;
    self.mtf = nil;
    NSInteger logical = 0;
    NSInteger freq = 0;
    NSUInteger size = 4;
    sysctlbyname("hw.logicalcpu", &logical, &size, NULL, 0);
    size = 8;
    sysctlbyname("hw.cpufrequency", &freq, &size, NULL, 0);
    self.logicalcpus = @(logical);
    self.cpufrequency = @(freq/1E6);
    self.generator = nil;
}

/*! \brief Generates an SSDT from the view's parameters
 *
 * \param sender Not used
 */
-(IBAction)generate:(id)sender {
    NSUInteger minFreq = 0;
    NSComparisonPredicate *powerSlope;
    bool ignoreValues = false;
    NSDictionary *fields = [PatchFile fieldsForPatch:_generator];
    if ([fields objectForKey:@"SSDT"]) {
        NSDictionary *ssdt = [fields objectForKey:@"SSDT"];
        if ([ssdt objectForKey:@"MinFreq"])
            minFreq = [[ssdt objectForKey:@"MinFreq"] integerValue];
        if ([ssdt objectForKey:@"PowerSlope"] && !(powerSlope = [NSComparisonPredicate parseExpression:[ssdt objectForKey:@"PowerSlope"]]))
            ModalError([NSError errorWithDomain:kMaciASLDomain code:kNSComparisonPredicateError userInfo:@{NSLocalizedDescriptionKey:@"Textual Math Parse Failure", NSLocalizedRecoverySuggestionErrorKey:@"The textual math entered could not be parsed by the NSPredicate parser, discarding it."}]);
        if ([@"true" caseInsensitiveCompare:[ssdt objectForKey:@"IgnoreValues"]] == NSOrderedSame)
            ignoreValues = true;
    }
    if (!ignoreValues) {
        if (!_mtf || !_logicalcpus || !_cpufrequency || !_tdp) {
            ModalError([NSError errorWithDomain:kMaciASLDomain code:kNULLSSDTError userInfo:@{NSLocalizedDescriptionKey:@"Missing Value", NSLocalizedRecoverySuggestionErrorKey:@"One or more values are empty"}]);
            return;
        }
        if (_cpufrequency.integerValue > _mtf.integerValue) {
            ModalError([NSError errorWithDomain:kMaciASLDomain code:kFreqRangeError userInfo:@{NSLocalizedDescriptionKey:@"Incorrect Range", NSLocalizedRecoverySuggestionErrorKey:@"CPU Frequency must be less than Max Turbo Frequency"}]);
            return;
        }
    }
    [_window performClose:sender];
    NSInteger logicalCpus = _logicalcpus.integerValue?:4;
    NSInteger freq = _cpufrequency.integerValue?:2900;
    NSInteger maxFreq = _mtf.integerValue?:freq+100;
    NSInteger thermal = _tdp.integerValue?:65;
    if (!minFreq) minFreq = 1600;
    if (!powerSlope) powerSlope = [NSComparisonPredicate parseExpression:@"max({min({floor(($freq-1)/$maxFreq),1}),0})*floor(($ratio / $maxRatio) * (((1.1 - (($maxRatio - $ratio) * 0.00625)) / 1.1) ** 2) * $tdp)+max({min({floor($maxFreq/$freq),1}),0})*$tdp"];
    NSInteger turboFreq = (maxFreq - freq) / 100;
    NSInteger maxRatio = maxFreq / 100;
    NSInteger pkgs = (maxFreq - minFreq + 100) / 100;
    NSInteger cpus = 0;
    NSMutableString *ssdt = [NSMutableString stringWithFormat:@"// Translated from RevoGirl's ssdtPRGen script v0.9\n// Generated with %ldW TDP, %ldMHz Max Turbo Freq\n", thermal, maxFreq];
    [ssdt appendString:@"DefinitionBlock (\"SSDT.aml\", \"SSDT\", 1, \"APPLE \", \"CpuPm\", 0x00001000)\n{\n"];
    while (cpus < logicalCpus)
        [ssdt appendFormat:@"    External (\\_PR_.%@, DeviceObj)\n", [self stringForCPU:cpus++]];
    [ssdt appendFormat:@"\n    Scope (_PR.%@)\n    {\n        Name (APSN, 0x%02lX)\n        Name (APSS, Package (0x%02lX)\n        {\n", [self stringForCPU:0], turboFreq, pkgs];
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
        [ssdt appendFormat:@"\n    Scope (\\_PR.%@)\n    {\n        Method (APSS, 0, NotSerialized)\n        {\n            Return (\\_PR.%@.APSS)\n        }\n    }\n", [self stringForCPU:cpus++], [self stringForCPU:0]];
    [ssdt appendString:@"}\n"];
    Document *doc = [DocumentController.sharedDocumentController newDocument:ssdt displayName:@"Generated SSDT" tableName:@"SSDT" tableset:nil display:true];
    if (doc)
        [doc quickPatch:_generator];
}

@end
