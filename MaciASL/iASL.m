//
//  iASL.m
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "iASL.h"
#import "Source.h"
#import "AppDelegate.h"
#import <objc/objc-runtime.h>

@interface DictionaryArray : NSObject

@property (readonly) NSString *key;
@property (readonly) id value;
@property (readonly) NSArray *children;

+(NSArray *)createWithDictionary:(NSDictionary *)dictionary;

@end

@implementation DictionaryArray

+(DictionaryArray *)createWithKey:(NSString *)key andValue:(id)value {
    DictionaryArray *temp = [DictionaryArray new];
    temp->_key = key;
    if ([value isKindOfClass:NSDictionary.class]) {
        temp->_children = [self createWithDictionary:value];
        temp->_value = [NSString stringWithFormat:@"%ld propert%s", [value count], [value count] == 1 ? "y" : "ies"];
    }
    else if ([value isKindOfClass:NSString.class])
        temp->_value = value;
    else if ([value isKindOfClass:NSNumber.class])
        temp->_value = [value stringValue];
    else if ([value isKindOfClass:NSData.class])
        temp->_value = [value description];
    else
        temp->_value = @"<Bad Value>";
    return temp;
}

+(NSArray *)createWithDictionary:(NSDictionary *)dictionary {
    NSMutableArray *temp = [NSMutableArray array];
    for (NSString *key in dictionary)
            [temp addObject:[self createWithKey:key andValue:[dictionary objectForKey:key]]];
    return [temp copy];
}

@end

@implementation iASLDecompilationResult

-(instancetype)initWithError:(NSError *)error string:(NSString *)string {
    self = [super init];
    if (self) {
        _error = error;
        _string = string;
    }
    return self;
}

@end

@implementation iASLCompilationResult

-(instancetype)initWithError:(NSError *)error string:(NSString *)string notices:(NSArray *)notices url:(NSURL *)url {
    self = [super initWithError:error string:string];
    if (self) {
        _notices = notices;
        _url = url;
    }
    return self;
}

@end

@implementation Notice

static NSRegularExpression *note;
static NSArray *typeIndex;

+(void)load {
    note = [NSRegularExpression regularExpressionWithPattern:@"(?:\\((\\d+)\\) : )?(warning|warning2|warning3|error|remark|optimize)\\s+(\\d+)(?: -|:) (.*)$" options:NSRegularExpressionCaseInsensitive error:nil];
    typeIndex = @[@"warning", @"warning2", @"warning3", @"error", @"remark", @"optimize"];
}

-(instancetype)initWithLine:(NSString *)line {
    self = [super init];
    if (self) {
        NSTextCheckingResult *result = [[note matchesInString:line options:0 range:NSMakeRange(0, line.length)] lastObject];
        if (!result)
            return nil;
        NSRange range = [result rangeAtIndex:1];
        _line = range.location == NSNotFound ? 1 : [[line substringWithRange:range] integerValue];
        _type = (iASLNoticeType)[typeIndex indexOfObject:[[line substringWithRange:[result rangeAtIndex:2]] lowercaseString]];
        _code = [[line substringWithRange:[result rangeAtIndex:3]] integerValue];
        _message = [line substringWithRange:[result rangeAtIndex:4]];
    }
    return self;
}

@end

@implementation iASL
NSURL *const kSystemTableset = (NSURL *)@"//System";
static NSDictionary *tableset, *stdTables;
static NSArray *deviceProperties;
static NSRegularExpression *signon;
static NSString *bootlog, *_compiler;
static NSUInteger _build;

+(void)load {
    stdTables = @{
        @"APIC":@"Multiple APIC Description Table (MADT)",
        @"ASF!":@"Alert Standard Format Table",
        @"BERT":@"Boot Error Record Table",
        @"BGRT":@"Boot Graphics Resource Table",
        @"BOOT":@"Simple Boot Flag Table",
        @"CPEP":@"Corrected Platform Error Polling Table",
        @"CSRT":@"Core System Resource Table",
        @"DBG2":@"Debug Port Table Type 2",
        @"DBGP":@"Debug Port Table",
        @"DMAR":@"DMA Remapping Table",
        @"DPPT":@"DMA Protection Policy Table",
        @"DRTM":@"Dynamic Root of Trust for Measurement Table",
        @"DSDT":@"Differentiated System Description Table",
        @"ECDT":@"Embedded Controller Boot Resources Table",
        @"EINJ":@"Error Injection Table",
        @"ERST":@"Error Record Serialization Table",
        @"ETDT":@"Event Timer Description Table (Obsolete)",
        @"FACP":@"Fixed ACPI Description Table (FADT)",
        @"FACS":@"Firmware ACPI Control Structure",
        @"FPDT":@"Firmware Performance Data Table",
        @"GTDT":@"Generic Timer Description Table",
        @"HEST":@"Hardware Error Source Table",
        @"HMAT":@"Heterogeneous Memory Attributes Table",
        @"HPET":@"High Precision Event Timer Table",
        @"IBFT":@"iSCSI Boot Firmware Table",
        @"IORT":@"I/O Remapping Table",
        @"IVRS":@"I/O Virtualization Reporting Structure",
        @"LPIT":@"Low Power Idle Table",
        @"MADT":@"Multiple APIC Description Table",
        @"MATR":@"Memory Address Translation Table",
        @"MCFG":@"PCI Memory Mapped Configuration Table",
        @"MCHI":@"Management Controller Host Interface Table",
        @"MPST":@"Memory Power State Table",
        @"MSCT":@"Maximum System Characteristics Table",
        @"MSDM":@"Microsoft Data Management Table",
        @"MTMR":@"MID Timer Table",
        @"NFIT":@"NVDIMM Firmware Interface Table",
        @"OSDT":@"Override System Description Table",
        @"PCCT":@"Platform Communications Channel Table",
        @"PMTT":@"Platform Memory Topology Table",
        @"PPTT":@"Processor Propertis Topology Table",
        @"PSDT":@"Persistent System Description Table",
        @"RASF":@"ACPI RAS Feature Table",
        @"RSDP":@"Root System Description Pointer",
        @"RSD PTR ":@"Root System Description Pointer Version 2",
        @"RSDT":@"Root System Description Table",
        @"S3PT":@"S3 Performance (sub)Table",
        @"SBST":@"Smart Battery Specification Table",
        @"SDEI":@"Software Delegated Exception Interface Table",
        @"SDEV":@"Secure Devices Table",
        @"SLIC":@"Microsoft Software Licensing Table Specification",
        @"SLIT":@"System Locality Distance Information",
        @"SPCR":@"Serial Port Console Redirection Table",
        @"SPMI":@"Server Platform Management Interface Table",
        @"SRAT":@"System Resource Affinity Table",
        @"SSDT":@"Secondary System Description Table",
        @"STAO":@"_STA Override Table",
        @"TCPA":@"Trusted Computing Platform Alliance Capabilities Table",
        @"TPM2":@"Trusted Platform Module 2.0 H/W Interface Table",
        @"UEFI":@"UEFI Boot Optimization Table",
        @"VRTC":@"Virtual Real-Time Clock Table",
        @"WAET":@"Windows ACPI Emulated Devices Table",
        @"WDAT":@"Watchdog Action Table",
        @"WDDT":@"Watchdog Timer Description",
        @"WDRT":@"Watchdog Resource Table",
        @"WPBT":@"Windows Patform Binary Table",
        @"WSMT":@"Windows SMM Security Migrations Table",
        @"XENV":@"Xen Project Table",
        @"XSDT":@"Extended System Description Table",
        @"XXXX":@"Intermediate AML Header for ASL/ASL+ Converter"
    };
    signon = [NSRegularExpression regularExpressionWithPattern:@"Compiler version (\\d+)" options:0 error:NULL];
    io_service_t expert;
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert")))) {
        tableset = (__bridge NSDictionary *)IORegistryEntryCreateCFProperty(expert, CFSTR("ACPI Tables"), kCFAllocatorDefault, 0);
        IOObjectRelease(expert);
    }
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice")))){
        CFDataRef data = IORegistryEntryCreateCFProperty(expert, CFSTR("boot-log"), kCFAllocatorDefault, 0);
        if (data){
            bootlog = [[NSString alloc] initWithData:(__bridge NSData *)data encoding:NSASCIIStringEncoding];
            CFRelease(data);
        }
        IOObjectRelease(expert);
    }
    if (!bootlog && (expert = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/efi/platform"))) {
        CFDataRef data = IORegistryEntryCreateCFProperty(expert, CFSTR("boot-log"), kCFAllocatorDefault, 0);
        if (data){
            bootlog = [[NSString alloc] initWithData:(__bridge NSData *)data encoding:NSASCIIStringEncoding];
            CFRelease(data);
        }
        IOObjectRelease(expert);
    }
    if (!bootlog) bootlog = @"";
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillFinishLaunching:) name:NSApplicationWillFinishLaunchingNotification object:nil];
}

+(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSApplicationWillFinishLaunchingNotification object:nil];
    io_service_t expert;
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert")))) {
        NSString *prefix = @"Presave ";
        NSMenu *menu = [NSMenu new];
        for (NSString *table in [tableset.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:table action:@selector(documentFromACPI:) keyEquivalent:@""], *alternate = [item copy];
            alternate.keyEquivalentModifierMask = NSAlternateKeyMask;
            alternate.alternate = true;
            if (table.length >= 4 && [stdTables objectForKey:[table substringToIndex:4]]) {
                NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithRTF:[[NSString stringWithFormat:@"{\\rtf1\\ansi {\\fonttbl\\f0 LucidaGrande;}\\f0\\fs28 %@%@\\line\\fs20 %@}", table, [table hasPrefix:@"SSDT"] ? [NSString stringWithFormat:@" (%@)", [[NSString alloc] initWithData:[[tableset objectForKey:table] subdataWithRange:NSMakeRange(16, 8)] encoding:NSASCIIStringEncoding]] : @"", [stdTables objectForKey:[table substringToIndex:4]]] dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
                item.attributedTitle = title;
                [title replaceCharactersInRange:NSMakeRange(0, 0) withString:prefix];
                alternate.attributedTitle = title;
                item.title = table;
            }
            else alternate.attributedTitle = [[NSAttributedString alloc] initWithString:[prefix stringByAppendingString:table] attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:14.0]}];
            alternate.title = table;
            [menu addItem:item];
            [menu addItem:alternate];
        }
        IOObjectRelease(expert);
        NSMenu *acpi = [[[NSApp mainMenu] itemAtIndex:1] submenu];
        [[acpi insertItemWithTitle:NSLocalizedString(@"new-from-acpi", @"New from ACPI") action:NULL keyEquivalent:@"" atIndex:1] setSubmenu:menu];
#ifdef DEBUG
        NSMenu *updates = [[[NSApp mainMenu] itemAtIndex:0] submenu];
        [updates removeItemAtIndex:1];
#endif
    }
    [NSUserDefaults.standardUserDefaults addObserver:(id)self forKeyPath:@"iasl" options:NSKeyValueObservingOptionInitial context:NULL];
}


+(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSMutableData *d = [NSMutableData data];
    AppDelegate *delegate = (AppDelegate *)[(NSApplication *)NSApp delegate];
    NSTask *t = [NSTask new];
    @try {
        t.launchPath = [NSBundle.mainBundle pathForAuxiliaryExecutable:
                        [NSString stringWithFormat:@"iasl-%@", [NSUserDefaults.standardUserDefaults stringForKey:@"iasl"]]];
        t.standardOutput = [NSPipe pipe];
        [[t.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *h) { [d appendData:h.availableData]; }];
        [t launch];
    }
    @catch (NSException *e) {
        if (delegate) [delegate logEntry:[NSString stringWithFormat:@"Could not launch %@", t.launchPath]];
        return;
    }
    [t waitUntilExit];
    NSArray *lines = [[[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"] subarrayWithRange:NSMakeRange(1, 5)];
    for (NSString *line in lines)
        if (delegate) [delegate logEntry:line];
    NSString *version = lines.lastObject;
    assignWithNotice(self, compiler, [lines componentsJoinedByString:@"\n"]);
    NSTextCheckingResult *result = [signon firstMatchInString:version options:0 range:NSMakeRange(0, version.length)];
    assignWithNotice(self, build, [[version substringWithRange:[result rangeAtIndex:1]] integerValue]);
}

+(NSString *)compiler {
    return _compiler;
}

+(NSUInteger)build {
    return _build;
}

+(NSDictionary *)tableset {
    return tableset;
}

+(NSArray *)deviceProperties {
    if (deviceProperties)
        return deviceProperties;
    io_iterator_t iter;
    io_registry_entry_t entry;
    NSMutableArray *properties = [NSMutableArray array];
    if (IORegistryEntryCreateIterator(IORegistryGetRootEntry(kIOMasterPortDefault), "IOACPIPlane", kIORegistryIterateRecursively, &iter) == KERN_SUCCESS) {
        while ((entry = IOIteratorNext(iter))) {
            NSMutableDictionary *prop;
            if (IORegistryEntryCreateCFProperties(entry, (void *)&prop, kCFAllocatorDefault, 0) == KERN_SUCCESS) {
                if ((prop = [prop objectForKey:@"device-properties"])) {
                    [prop removeObjectsForKeys:@[@"acpi-device", @"acpi-path"]];
                    io_name_t name;
                    if (prop.count && IORegistryEntryGetName(entry, name) == KERN_SUCCESS)
                        [properties addObject:[DictionaryArray createWithKey:[NSString stringWithUTF8String:name] andValue:prop]];
                }
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    return deviceProperties = [properties copy];
}

+(NSString *)isInjected:(NSURL *)url {
    return [[self.tableset allKeysForObject:[NSData dataWithContentsOfURL:url]] firstObject];
}

+(NSURL *)wasInjected:(NSString *)table {
    NSString *file;
    NSRange range;
    if ((range = [bootlog rangeOfString:[table stringByAppendingString:@"="] options:NSCaseInsensitiveSearch]).location != NSNotFound) {
        range = NSMakeRange(NSMaxRange(range), bootlog.length-NSMaxRange(range));
        NSRange end = [bootlog rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:0 range:range];
        file = [bootlog substringWithRange:(end.location == NSNotFound)?range:NSMakeRange(range.location, end.location-range.location)];
        if ([file.lowercaseString isEqualToString:@"null"])
            file = nil;
    }
    else if ([bootlog rangeOfString:[NSString stringWithFormat:@"/Extra/%@.aml]", table] options:NSCaseInsensitiveSearch].location != NSNotFound)
        file = [NSString stringWithFormat:@"/Extra/%@.aml", table];
    else if ((range = [bootlog rangeOfString:[table stringByAppendingString:@" found in Clover volume OEM folder: "] options:NSCaseInsensitiveSearch]).location != NSNotFound || (range = [bootlog rangeOfString:[table stringByAppendingString:@" found in Clover volume: "] options:NSCaseInsensitiveSearch]).location != NSNotFound)
        file = [[bootlog substringWithRange:NSMakeRange(NSMaxRange(range), NSMaxRange([bootlog lineRangeForRange:range])-NSMaxRange(range)-1)] stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    else if ([bootlog rangeOfString:[table stringByAppendingString:@" found in booted volume"] options:NSCaseInsensitiveSearch].location != NSNotFound)
        file = [@"/" stringByAppendingFormat:@"%@.aml",table];
    return file ? [NSURL fileURLWithPath:file] : nil;
}

+(NSURL *)tempFile:(NSString *)template {
    char *temp;
    close(mkstemps(temp = strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:template] fileSystemRepresentation]), (int)template.pathExtension.length + 1));
    NSURL *url = (__bridge_transfer NSURL *)CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)temp, strlen(temp), false);
    free(temp);
    return url;
}

+(NSURL *)tempAML {
    return [self tempFile:@"iASLXXXXXX.aml"];
}

+(NSURL *)tempDSL {
    return [self tempFile:@"iASLXXXXXX.dsl"];
}

+(NSData *)fetchTable:(NSString *)name {
    if ([tableset objectForKey:name])
        return [tableset objectForKey:name];
    ModalError([NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:@{NSLocalizedDescriptionKey:@"Table Retrieval Error", NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"Error fetching %@ from IORegistry",name]}]);
    return nil;
}

+(NSError *)taskWithURL:(NSURL *)url arguments:(NSArray *)arguments output:(NSArray * __strong *)output error:(NSArray * __strong *)error {
    NSTask *task = [NSTask new];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-vs", @"-vi", nil];
    NSString *iasl = [defaults stringForKey:@"iasl"];
    if (![defaults boolForKey:@"remarks"])
        [args addObject:@"-vr"];
    if ([defaults boolForKey:@"optimizations"])
        [args addObject:@"-vo"];
    if ([defaults boolForKey:@"werror"] && ![iasl isEqualToString:@"legacy"])
        [args addObject:@"-we"];
    [args addObjectsFromArray:arguments];
    @try {
        task.launchPath = [NSBundle.mainBundle pathForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl-%@", iasl]];
        task.arguments = [args copy];
        task.currentDirectoryPath = url.URLByDeletingLastPathComponent.path;
        task.standardOutput = [NSPipe pipe];
        task.standardError = [NSPipe pipe];
        [task launch];
    }
    @catch (NSException *e) {
        return [NSError errorWithDomain:kMaciASLDomain code:0 userInfo:@{NSLocalizedRecoverySuggestionErrorKey:@"The compiler could not be found, or is not executable."}];
    }
    AppDelegate *delegate = [AppDelegate safeDelegate];
    dispatch_apply(2, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t isOutput) {
        NSFileHandle *h = [isOutput ? task.standardOutput : task.standardError fileHandleForReading];
        NSData *d;
        NSMutableArray *lines = [NSMutableArray array];
        NSMutableString *buffer = [NSMutableString string];
        while ((d = h.availableData)) {
            if (!d.length)
                break;
            [buffer appendString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
            NSRange r;
            while ((r = [buffer rangeOfString:@"\n"]).location != NSNotFound) {
                if (r.location) {
                    [lines addObject:[buffer substringWithRange:NSMakeRange(0, r.location)]];
                    if (delegate)
                        [delegate performSelectorOnMainThread:@selector(logEntry:) withObject:lines.lastObject waitUntilDone:false];
                }
                [buffer deleteCharactersInRange:NSMakeRange(0, NSMaxRange(r))];
            }
        }
        if (buffer.length) {
            [lines addObject:[buffer copy]];
            if (delegate)
                [delegate performSelectorOnMainThread:@selector(logEntry:) withObject:lines.lastObject waitUntilDone:false];
        }
        if (isOutput && output)
            *output = [lines copy];
        else if (!isOutput && error)
            *error = [lines copy];
    });
    [task waitUntilExit];
    NSString *suggestion = task.terminationStatus ? [NSString stringWithFormat:@"iASL returned:\n%@\n%@", [*output componentsJoinedByString:@"\n"], [*error componentsJoinedByString:@"\n"]] : nil, *failure = suggestion && task.terminationReason == NSTaskTerminationReasonUncaughtSignal ? [NSString stringWithFormat:@"The compiler crashed with code %d.", task.terminationStatus] : nil;
    return suggestion ? [NSError errorWithDomain:kMaciASLDomain code:task.terminationStatus userInfo:failure ? @{NSLocalizedFailureReasonErrorKey:failure, NSLocalizedRecoverySuggestionErrorKey:suggestion} : @{NSLocalizedRecoverySuggestionErrorKey:suggestion}] : nil;
}

+(iASLDecompilationResult *)decompileAML:(NSData *)aml name:(NSString *)name tableset:(NSURL *)tableset refs:(NSURL *)refs {
    NSDictionary *tables = nil;

    if ([tableset isEqual:kSystemTableset]) {
        tables = self.tableset;
    } else if ([tableset isFileURL]) {
        tables = [(NSDictionary *)[NSDictionary dictionaryWithContentsOfURL:tableset] objectForKey:@"Tables"];
    }
    NSMutableArray *externals;
    if ([name hasPrefix:@"SSDT"] || [name isEqualToString:@"DSDT"]) {
        for (NSString *table in tables)
            if (![table isEqualToString:name] && ([table hasPrefix:@"SSDT"] || [table isEqualToString:@"DSDT"])) {
                if (!externals)
                    externals = [NSMutableArray array];
                [externals addObject:self.tempAML];
                [[tables objectForKey:table] writeToURL:externals.lastObject atomically:true];
            }
    }
    NSURL *url = self.tempAML;
    [aml writeToURL:url atomically:true];
    NSArray *output, *error;

    NSMutableArray *args = [[NSMutableArray alloc] init];
    NSString *extra = [NSUserDefaults.standardUserDefaults stringForKey:@"extradecomp"];
    if (extra) {
        extra = [extra stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([extra length] > 0)
            [args addObjectsFromArray:[extra componentsSeparatedByString:@" "]];
    }

    if (externals) {
        if ([[NSUserDefaults.standardUserDefaults stringForKey:@"iasl"] isEqualToString:@"legacy"])
            [args addObjectsFromArray:@[@"-e", [[externals valueForKey:@"lastPathComponent"] componentsJoinedByString:@","]]];
        else
            [args addObjectsFromArray:[@[@"-e"] arrayByAddingObjectsFromArray:[externals valueForKey:@"lastPathComponent"]]];
    }

    if (refs) {
        [args addObjectsFromArray:@[@"-fe", refs.path]];
    }

    NSError *result = [self taskWithURL:url arguments:[args arrayByAddingObjectsFromArray:@[@"-d", url.lastPathComponent]] output:&output error:&error];
    NSError *err;
    NSFileManager *manager = NSFileManager.defaultManager;
    for (NSURL *external in externals)
        if (![manager removeItemAtURL:external error:&err])
            ModalError(err);
    if (![manager removeItemAtURL:url error:&err])
        ModalError(err);
    if (!result) {
        url = [url.URLByDeletingPathExtension URLByAppendingPathExtension:@"dsl"];
        NSString *dsl = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
        ModalError(err);
        if (![manager removeItemAtURL:url error:&err])
            ModalError(err);
        NSRange range = [dsl rangeOfString:@"/*\n * "];
        if (range.location) {
            range = NSMakeRange(0, range.location - 1);
            dsl = [dsl stringByReplacingCharactersInRange:range withString:[@"// " stringByAppendingString:[[dsl substringWithRange:range] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n// "]]];
        }
        return [[iASLDecompilationResult alloc] initWithError:nil string:dsl];
    }
    else if (externals) {
        [[AppDelegate safeDelegate] logEntry:@"Decompilation with resolution failed, trying without resolution"];
        return [self decompileAML:aml name:name tableset:nil refs:nil];
    }
    else {
        NSMutableDictionary *d = [result.userInfo mutableCopy];
        [d setObject:@"Decompilation Error" forKey:NSLocalizedDescriptionKey];
        return [[iASLDecompilationResult alloc] initWithError:[NSError errorWithDomain:kMaciASLDomain code:kDecompileError userInfo:[d copy]] string:nil];
    }
}

+(iASLCompilationResult *)compileDSL:(NSString *)dsl name:(NSString *)name tableset:(NSURL *)tableset force:(bool)force {
    NSURL *url = self.tempDSL;
    NSError *err;
    if (![dsl writeToURL:url atomically:true encoding:NSASCIIStringEncoding error:&err])
        ModalError(err);
    NSArray *output, *error;

    NSMutableArray *args = [[NSMutableArray alloc] init];
    NSString *extra = [NSUserDefaults.standardUserDefaults stringForKey:@"extracomp"];
    if (extra) {
        extra = [extra stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([extra length] > 0)
            [args addObjectsFromArray:[extra componentsSeparatedByString:@" "]];
    }

    if (force) {
        [args addObject:@"-f"];
    }

    NSError *result = [self taskWithURL:url arguments:[args arrayByAddingObjectsFromArray:@[@"-p", url.lastPathComponent.stringByDeletingPathExtension, url.lastPathComponent]] output:&output error:&error];
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager removeItemAtURL:url error:&err])
        ModalError(err);
    url = [url.URLByDeletingPathExtension URLByAppendingPathExtension:@"aml"];
    NSMutableArray *notices = [NSMutableArray array];
    Notice *notice;
    for (NSString *line in output)
        if ((notice = [[Notice alloc] initWithLine:line]))
            [notices addObject:notice];
    // Custom-compiled iasl may output errors to stderr instead of stdout.
    if (![[NSUserDefaults.standardUserDefaults stringForKey:@"iasl"] isEqualToString:@"legacy"]) {
        for (NSString *line in error)
            if ((notice = [[Notice alloc] initWithLine:line]))
                [notices addObject:notice];
    }
    if (result) {
        NSMutableDictionary *d = [result.userInfo mutableCopy];
        [d setObject:@"Compilation Error" forKey:NSLocalizedDescriptionKey];
        result = [NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:[d copy]];
    }

    // New compilers may append extra strings after error count
    NSString *str = @"";
    NSUInteger count = [output count];
    if (count > 0) {
        str = [[output.lastObject componentsSeparatedByString:@". "] lastObject];
        if (count > 1 && [str hasPrefix:@"No AML files were generated"]) {
            str = [[[output objectAtIndex:count-2] componentsSeparatedByString:@". "] lastObject];
        }
    }

    return [[iASLCompilationResult alloc] initWithError:!result && [url checkResourceIsReachableAndReturnError:&err] ? nil : result string:str notices:[notices copy] url:url];
}

@end

@interface TypeTransformer : NSValueTransformer

@end

@implementation TypeTransformer

+(Class)transformedValueClass {
    return [NSImage class];
}

+(BOOL)allowsReverseTransformation {
    return false;
}

-(id)transformedValue:(id)value {
    if (!value) return nil;
    OSType ftc = kAlertNoteIcon;
    switch ([value integerValue]) {
        case iASLNoticeTypeError:
            ftc = kAlertStopIcon;
            break;
        case iASLNoticeTypeWarning:
        case iASLNoticeTypeWarning2:
        case iASLNoticeTypeWarning3:
            ftc = kAlertCautionIcon;
            break;
        case iASLNoticeTypeRemark:
            ftc = kAlertNoteIcon;
            break;
        case iASLNoticeTypeOptimization:
            ftc = kToolbarCustomizeIcon;
            break;
    }
    return [NSWorkspace.sharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(ftc)];
}

@end

@implementation URLTask
static dispatch_semaphore_t s;
static NSDateFormatter *rfc822;

+(void)load {
    s = dispatch_semaphore_create(1);
    rfc822 = [NSDateFormatter new];
    rfc822.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    rfc822.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    rfc822.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
}

+(void)get:(NSURL *)url toURL:(NSURL *)file perform:(void(^)(bool))handler {
    NSError *err = nil;
    NSDate *filemtime = nil;
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    BOOL present = [file getResourceValue:&filemtime forKey:NSURLContentModificationDateKey error:&err];
    
    if ((present && !ModalError(err)) || !present) {
        dispatch_async(dispatch_queue_create(nil, 0), ^{
            NSError *error;
            bool result = [[NSData dataWithContentsOfURL:url options:0 error:&error] writeToURL:file
                                                                                   options:NSDataWritingAtomic
                                                                                     error:nil];
            if (!ModalError(error) && result) {
                [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0755 }
                                                 ofItemAtPath:file.path
                                                        error:nil];
            }
            progress.completedUnitCount++;
            dispatch_async(dispatch_get_main_queue(), ^{ handler(result); });

        });
    }
    else {
        progress.completedUnitCount++;
        dispatch_async(dispatch_get_main_queue(), ^{ handler(false); });
    }
}


+(void)conditionalGet:(NSURL *)url toURL:(NSURL *)file perform:(void(^)(bool))handler {
    NSError *err = nil;
    NSDate *filemtime = nil;
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:2];
    BOOL present = [file getResourceValue:&filemtime forKey:NSURLContentModificationDateKey error:&err];
    if ((present && !ModalError(err)) || !present) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"HEAD";
        [NSURLConnection sendAsynchronousRequest:[request copy] queue:SourceList.sharedList.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            progress.completedUnitCount++;
            bool result = false;
            if (!ModalError(connectionError)) {
                NSDictionary *d = [(NSHTTPURLResponse *)response allHeaderFields];
                dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
                NSDate *urlmtime = [rfc822 dateFromString:[d objectForKey:@"Last-Modified"]];
                dispatch_semaphore_signal(s);
                NSNumber *urlsize = @([[d objectForKey:@"Content-Length"] integerValue]), *filesize;
                BOOL download = NO;
                if (present) {
                    if (![file getResourceValue:&filesize forKey:NSURLFileSizeKey error:&connectionError])
                        ModalError(connectionError);
                    else if ((!urlmtime || [filemtime compare:urlmtime] == NSOrderedAscending) && ![urlsize isEqualToNumber:filesize])
                        download = YES;
                } else {
                    download = YES;
                }

                if (download) {
                    result = [[NSData dataWithContentsOfURL:url options:0 error:NULL] writeToURL:file
                                                                                         options:NSDataWritingAtomic
                                                                                           error:&connectionError];
                    if (result) {
                        [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0755 }
                                                         ofItemAtPath:file.path
                                                                error:nil];
                        [file setResourceValue:urlmtime forKey:NSURLContentModificationDateKey error:&connectionError];
                        ModalError(connectionError);
                    }
                }
            }
            progress.completedUnitCount++;
            dispatch_async(dispatch_get_main_queue(), ^{ handler(result); });
        }];
    }
    else {
        progress.completedUnitCount += 2;
        dispatch_async(dispatch_get_main_queue(), ^{ handler(false); });
    }
}

@end
