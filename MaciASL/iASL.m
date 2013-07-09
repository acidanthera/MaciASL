//
//  iASL.m
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "iASL.h"
#import "AppDelegate.h"
#import <objc/objc-runtime.h>

@implementation iASL
static NSDictionary *tableset;
static NSDictionary *stdTables;
static NSString *bootlog;

@synthesize task;
@synthesize status;

+(void)initialize{
    stdTables = @{@"APIC":@"Advanced Programmable Interrupt Controller", @"ASF!":@"Alert Standard Format", @"BOOT":@"Simple Boot Flag", @"BERT":@"Boot Error Record", @"BGRT":@"Boot Graphics Resource", @"CPEP":@"Corrected Platform Error Polling", @"DBGP":@"Debug Port", @"DMAR":@"DMA Remapping", @"DRTM":@"Dynamic Root of Trust for Measurement", @"DSDT": @"Differentiated System Description", @"ECDT":@"Embedded Controller Boot Resources", @"EINJ":@"Error Injection", @"ERST":@"Error Record Serialization", @"FACP":@"Fixed ACPI Control Pointer", @"FACS":@"Firmware ACPI Control Structure", @"FADT":@"Fixed ACPI Description", @"FPDT":@"Firmware Performance Data", @"GTDT":@"Generic Timer Description", @"HEST":@"Hardware Error Source", @"HPET":@"High Precision Event Timer", @"MPST":@"Memory Power State", @"IVRS":@"I/O Virtualization Reporting Structure", @"MADT":@"Multiple APIC Description", @"MCFG":@"PCI Memory Mapped Configuration", @"MCHI":@"Management Controller Host Interface", @"MSCT":@"Maximum System Characteristics", @"PCCT":@"Platform Communications Channel", @"PMTT":@"Platform Memory Topology", @"RASF":@"RAS Feature", @"RSDP":@"Root System Description Pointer", @"RSDT":@"Root System Description", @"SBST":@"Smart Battery Specification", @"SLIC":@"Software Licensing Description", @"SLIT":@"System Locality Distance Information", @"SPCR":@"Serial Port Console Redirection", @"SPMI":@"Server Platform Management Interface", @"SRAT":@"System Resource Affinity", @"SSDT":@"Secondary System Description", @"TCPA":@"Trusted Computing Platform Alliance", @"UEFI":@"Uefi Boot Optimization", @"WAET":@"Windows ACPI Emulated devices", @"WDAT":@"Watchdog Action", @"WDDT":@"Watchdog Timer Description", @"WDRT":@"Watchdog Resource", @"XSDT":@"Extended System Description"};
    io_service_t expert;
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert")))) {
        tableset = (__bridge NSDictionary *)IORegistryEntryCreateCFProperty(expert, CFSTR("ACPI Tables"), kCFAllocatorDefault, 0);
        NSString *prefix = @"Presave ";
        for (NSString *table in [tableset.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:table action:@selector(documentFromACPI:) keyEquivalent:@""], *alternate = [item copy];
            alternate.keyEquivalentModifierMask = NSAlternateKeyMask;
            alternate.alternate = true;
            if (table.length >= 4 && [stdTables objectForKey:[table substringToIndex:4]]) {
                NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithRTF:[[NSString stringWithFormat:@"{\\rtf1\\ansi {\\fonttbl\\f0 LucidaGrande;}\\fs28 %@\\line\\fs20 %@}", table, [stdTables objectForKey:[table substringToIndex:4]]] dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
                item.attributedTitle = title;
                [title replaceCharactersInRange:NSMakeRange(0, 0) withString:prefix];
                alternate.attributedTitle = title;
                item.title = table;
            }
            else alternate.attributedTitle = [[NSAttributedString alloc] initWithString:[prefix stringByAppendingString:table] attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:14.0]}];
            alternate.title = table;
            [[[NSApp delegate] tables] addItem:item];
            [[[NSApp delegate] tables] addItem:alternate];
        }
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
}
+(NSDictionary *)tableset {
    return tableset;
}
+(NSString *)wasInjected:(NSString *)table{
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
    return file;
}
+(NSString *)tempFile:(NSString *)template{
    char *temp = (char *)[[NSTemporaryDirectory() stringByAppendingPathComponent:template] fileSystemRepresentation];
    close(mkstemps(temp, (int)template.pathExtension.length+1));
    unlink(temp);
    return [NSFileManager.defaultManager stringWithFileSystemRepresentation:temp length:strlen(temp)];
}
+(NSData *)fetchTable:(NSString *)name{
    if ([tableset objectForKey:name])
        return [tableset objectForKey:name];
    ModalError([NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:@{NSLocalizedDescriptionKey:@"Table Retrieval Error", NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"Error fetching %@ from IORegistry",name]}]);
    return nil;
}
+(NSDictionary *)decompile:(NSData *)aml withResolution:(NSString *)tableset {
    NSArray *args = @[];
    NSMutableArray *amls;
    NSDictionary *tabs;
    if (tableset && (tabs = [tableset isEqualToString:kSystemTableset]?self.tableset:[[NSDictionary dictionaryWithContentsOfFile:tableset] objectForKey:@"Tables"]) && [[tabs allKeysForObject:aml] containsObject:@"DSDT"]) {
        amls = [NSMutableArray array];
        for (NSString *table in tabs) {
            if (![table hasPrefix:@"SSDT"]) continue;
            [amls addObject:[iASL tempFile:@"iASLXXXXXX.aml"]];
            [NSFileManager.defaultManager createFileAtPath:amls.lastObject contents:[tabs objectForKey:table] attributes:nil];
        }
        args = @[@"-e",[[amls valueForKey:@"lastPathComponent"] componentsJoinedByString:@","]];
    }
    NSString *path = [iASL tempFile:@"iASLXXXXXX.aml"];
    [NSFileManager.defaultManager createFileAtPath:path contents:aml attributes:nil];
    iASL *decompile = [iASL create:[args arrayByAddingObjectsFromArray:@[@"-d",path.lastPathComponent]] withFile:path];
    NSError *err;
    for (NSString *aml in amls)
        if (![NSFileManager.defaultManager removeItemAtPath:aml error:&err])
            ModalError(err);
    if (!decompile.status) {
        if (amls) {
            [[NSApp delegate] logEntry:@"Decompilation with resolution failed, trying without resolution"];
            return [self decompile:aml withResolution:nil];
        }
        else return @{@"status":@(decompile.status), @"object":[NSError errorWithDomain:kMaciASLDomain code:kDecompileError userInfo:@{NSLocalizedDescriptionKey:@"Decompilation Error", NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"iASL returned:\n%@\n%@", decompile.stdOut, decompile.stdErr]}]};
    }
    path = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"dsl"];
    NSString *dsl = [[NSString alloc] initWithData:[NSFileManager.defaultManager contentsAtPath:path] encoding:NSASCIIStringEncoding];
    if (![NSFileManager.defaultManager removeItemAtPath:path error:&err])
        ModalError(err);
    NSRange block = [dsl rangeOfString:@"/*\n * "];
    if (block.location) {
        block = NSMakeRange(0, block.location-1);
        dsl = [dsl stringByReplacingCharactersInRange:block withString:[@"// " stringByAppendingString:[[[dsl substringWithRange:block] componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n// "]]];
    }
    return @{@"status":@(decompile.status), @"object":dsl};
}
//TODO: add redecompile option? how to detect smallest number of changes?
+(NSDictionary *)compile:(NSString *)dsl force:(bool)force{
    NSString *path = [iASL tempFile:@"iASLXXXXXX.dsl"];
    [NSFileManager.defaultManager createFileAtPath:path contents:[dsl dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
    NSArray *args = @[@"-p", path.lastPathComponent.stringByDeletingPathExtension, path.lastPathComponent];
    iASL *compile = [iASL create:force?[@[@"-f"] arrayByAddingObjectsFromArray:args]:args withFile:path];
    path = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"aml"];
    NSMutableArray *temp = [NSMutableArray array];
    Notice *notice;
    for (NSString *line in ([NSUserDefaults.standardUserDefaults integerForKey:@"acpi"] == 4)?compile.task.stdOut:compile.task.stdErr)
        if ((notice = [Notice create:line]))
            [temp addObject:notice];
    return @{@"notices":[temp copy], @"summary":[[[compile.task.stdOut lastObject] componentsSeparatedByString:@". "] lastObject], @"aml":path, @"success":@(compile.status && [NSFileManager.defaultManager fileExistsAtPath:path])};
}
+(iASL *)create:(NSArray *)args withFile:(NSString *)file{
    NSMutableArray *arguments = [@[@"-vs", @"-vi"] mutableCopy];
    [arguments addObjectsFromArray:args];
    iASL *temp = [iASL new];
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"remarks"])
        [arguments insertObject:@"-vr" atIndex:0];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"optimizations"])
        [arguments insertObject:@"-vo" atIndex:0];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"werror"] && [NSUserDefaults.standardUserDefaults integerForKey:@"acpi"] > 4)
        [arguments insertObject:@"-we" atIndex:0];
    temp.task = [NSTask create:[NSBundle.mainBundle pathForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl%ld", [NSUserDefaults.standardUserDefaults integerForKey:@"acpi"]]] args:arguments callback:@selector(logEntry:) listener:[NSApp delegate]];
    if (file) temp.task.currentDirectoryPath = file.stringByDeletingLastPathComponent;
    [temp.task launchAndWait];
    NSError *err;
    if (file && ![NSFileManager.defaultManager removeItemAtPath:file error:&err])
        ModalError(err);
    temp.status = (!err && temp.task.terminationReason == NSTaskTerminationReasonExit && temp.task.terminationStatus == 0);
    return temp;
}
-(NSString *)stdOut{
    return [self.task.stdOut componentsJoinedByString:@"\n"];
}
-(NSString *)stdErr{
    return [self.task.stdErr componentsJoinedByString:@"\n"];
}
@end

@implementation Notice
@synthesize type;
@synthesize line;
@synthesize code;
@synthesize message;

static NSRegularExpression *note;
static NSArray *typeIndex;

+(void)initialize{
    note = [NSRegularExpression regularExpressionWithPattern:@"(?:\\((\\d+)\\) : )?(warning|warning2|warning3|error|remark|optimize)\\s+(\\d+)(?: -|:) (.*)$" options:NSRegularExpressionCaseInsensitive error:nil];
    typeIndex = @[@"warning", @"warning2", @"warning3", @"error", @"remark", @"optimize"];
}
+(Notice *)create:(NSString *)entry{
    __block Notice *temp = [Notice new];
    [note enumerateMatchesInString:entry options:0 range:NSMakeRange(0, entry.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        NSRange line = [result rangeAtIndex:1];
        temp.line = (line.location == NSNotFound)?1:[[entry substringWithRange:line] integerValue];
        temp.type = (enum noticeType)[typeIndex indexOfObject:[[entry substringWithRange:[result rangeAtIndex:2]] lowercaseString]];
        temp.code = [[entry substringWithRange:[result rangeAtIndex:3]] integerValue];
        temp.message = [entry substringWithRange:[result rangeAtIndex:4]];
    }];
    return !temp.message?nil:temp;
}

@end

@implementation TypeTransformer

+(Class)transformedValueClass{
    return [NSImage class];
}
+(BOOL)allowsReverseTransformation{
    return false;
}
-(id)transformedValue:(id)value{
    if (!value) return nil;
    OSType ftc = kAlertNoteIcon;
    switch ([value integerValue]) {
        case error:
            ftc = kAlertStopIcon;
            break;
        case warning:
        case warning2:
        case warning3:
            ftc = kAlertCautionIcon;
            break;
        case remark:
            ftc = kAlertNoteIcon;
            break;
        case optimization:
            ftc = kToolbarCustomizeIcon;
            break;
    }
    return [NSWorkspace.sharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(ftc)];
}

@end

@implementation NSTask (TaskAdditions)

static char kCallbackKey;
static char kListenerKey;
static char kErrKey;
static char kOutKey;
static char kLockKey;

@dynamic stdErr, stdOut;
-(NSArray *)stdErr{
    return objc_getAssociatedObject(self, &kErrKey);
}
-(NSArray *)stdOut{
    return objc_getAssociatedObject(self, &kOutKey);
}
-(void)setCallback:(SEL)callback{
    objc_setAssociatedObject(self, &kCallbackKey, NSStringFromSelector(callback), OBJC_ASSOCIATION_RETAIN);
}
-(SEL)callback{
    return NSSelectorFromString(objc_getAssociatedObject(self, &kCallbackKey));
}
-(void)setListener:(id)listener{
    objc_setAssociatedObject(self, &kListenerKey, listener, OBJC_ASSOCIATION_RETAIN);
}
-(id)listener{
    return objc_getAssociatedObject(self, &kListenerKey);
}

+(NSTask *)create:(NSString *)path args:(NSArray *)arguments callback:(SEL)selector listener:(id)object{
    NSTask *temp = [NSTask new];
    objc_setAssociatedObject(temp, &kLockKey, [NSConditionLock new], OBJC_ASSOCIATION_RETAIN);
    temp.launchPath = path;
    temp.arguments = arguments;
    temp.listener = object;
    temp.callback = selector;
    temp.standardError = [NSPipe pipe];
    temp.standardOutput = [NSPipe pipe];
    [temp performSelectorInBackground:@selector(read:) withObject:[temp.standardError fileHandleForReading]];
    [temp performSelectorInBackground:@selector(read:) withObject:[temp.standardOutput fileHandleForReading]];
    return temp;
}
-(void)launchAndWait{
    NSConditionLock *cond = objc_getAssociatedObject(self, &kLockKey);
    [cond waitOn:2];
    [self launch];
    [self waitUntilExit];
    [cond waitOn:0];
}
-(void)read:(NSFileHandle *)handle{
    NSMutableArray *lines = [NSMutableArray array];
    NSMutableString *buffer = [NSMutableString string];
    NSData *data;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSConditionLock *cond = objc_getAssociatedObject(self, &kLockKey);
    [cond increment];
    while ((data = [handle availableData])){
        if (!data.length) {
            if (buffer.length) {
                if (self.listener) [self.listener performSelector:self.callback withObject:buffer];
                [lines addObject:buffer];
            }
            break;
        }
        else {
            [buffer appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            if ([buffer rangeOfString:@"\n"].location == NSNotFound) continue;
            NSArray *temp = [buffer componentsSeparatedByString:@"\n"];
            for (NSString *line in [temp subarrayWithRange:NSMakeRange(0, temp.count-1)]) {
                if (!line.length) continue;
                if (self.listener) [self.listener performSelectorOnMainThread:self.callback withObject:line waitUntilDone:false];
                [lines addObject:line];
            }
            buffer.string = temp.lastObject;
        }
    }
    #pragma clang diagnostic pop
    objc_setAssociatedObject(self, (handle == [self.standardError fileHandleForReading]) ? &kErrKey : &kOutKey, [lines copy], OBJC_ASSOCIATION_RETAIN);
    [cond decrement];
}

@end

@implementation NSConditionLock (NSTaskAdditions)

-(void)waitOn:(NSUInteger)condition{
    [self lockWhenCondition:condition];
    [self unlockWithCondition:condition];
}
-(void)increment{
    [self lock];
    [self unlockWithCondition:self.condition+1];
}
-(void)decrement{
    [self lock];
    [self unlockWithCondition:self.condition-1];
}

@end

@implementation URLTask

+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file{
    NSError *err;
    NSDate *filemtime = [[NSFileManager.defaultManager attributesOfItemAtPath:file error:&err] fileModificationDate];
    if (ModalError(err)) return false;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    NSHTTPURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (ModalError(err)) return false;
    NSString *urlmstr = [response.allHeaderFields objectForKey:@"Last-Modified"];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *urlmtime = [df dateFromString:urlmstr];
    bool changed = ([filemtime compare:urlmtime] == NSOrderedAscending);
    if (changed)
        if (![[NSData dataWithContentsOfURL:url] writeToFile:file options:NSDataWritingAtomic error:&err])
            if (ModalError(err)) return false;
    if (![NSFileManager.defaultManager setAttributes:@{NSFileModificationDate: urlmtime} ofItemAtPath:file error:&err])
        if (ModalError(err)) return false;
    return changed;
}

@end
