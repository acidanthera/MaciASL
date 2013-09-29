//
//  GetMetadataForFile.m
//  ACPIImporter
//
//  Created by PHPdev32 on 9/17/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#include <Foundation/Foundation.h>

static NSRegularExpression *_string;

NSArray *StringsForAML(NSData *aml) {
    if (!_string)
        _string = [NSRegularExpression regularExpressionWithPattern:@"\x0D([\x20-\x7E]{2,})\x00" options:0 error:nil];
    __block NSMutableSet *strings = [NSMutableSet set];
    [_string enumerateMatchesInString:[[NSString alloc] initWithData:aml encoding:NSASCIIStringEncoding] options:0 range:NSMakeRange(0, aml.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [strings addObject:[[NSString alloc] initWithData:[aml subdataWithRange:[result rangeAtIndex:1]] encoding:NSASCIIStringEncoding]];
    }];
    return [strings allObjects];
}

bool MetadataForAML(NSData *aml, CFMutableDictionaryRef metadata) {
    struct {
        UInt8 Signature[4];
        UInt32 Length;
        UInt8 Revision;
        UInt8 Checksum;
        UInt8 OemId[6];
        UInt8 OemTableId[8];
        UInt32 OemRevision;
        UInt8 AslCompilerId[4];
        UInt32 AslCompilerRevision;
    } header;
    [aml getBytes:&header range:NSMakeRange(0, sizeof(header))];
    CFTypeRef item = CFStringCreateWithFormat(kCFAllocatorDefault, 0, CFSTR("%c%c%c%c %d"), header.Signature[0], header.Signature[1], header.Signature[2], header.Signature[3], header.Revision);
    CFDictionaryAddValue(metadata, kMDItemTitle, item);
    CFRelease(item);
    if (memcmp(header.Signature, "FACS", 4) == 0)
        return true;
    if (header.OemId[0]) {
        CFTypeRef items[] = {CFStringCreateWithBytes(kCFAllocatorDefault, header.OemId, 6, kCFStringEncodingASCII, false)};
        item = CFArrayCreate(kCFAllocatorDefault, items, 1, NULL);
        CFDictionaryAddValue(metadata, kMDItemOrganizations, item);
        CFRelease(item);
    }
    if (header.OemTableId[0]) {
        item = CFStringCreateWithBytes(kCFAllocatorDefault, header.OemTableId, 8, kCFStringEncodingASCII, false);
        CFDictionaryAddValue(metadata, kMDItemSubject, item);
        CFRelease(item);
    }
    if (header.AslCompilerId[0]) {
        item = CFStringCreateWithFormat(kCFAllocatorDefault, 0, CFSTR("%c%c%c%c %x"), header.AslCompilerId[0], header.AslCompilerId[1], header.AslCompilerId[2], header.AslCompilerId[3], header.AslCompilerRevision);
        CFDictionaryAddValue(metadata, kMDItemCreator, item);
        CFRelease(item);
    }
    if (header.OemRevision) {
        item = CFStringCreateWithFormat(kCFAllocatorDefault, 0, CFSTR("%#010x"), header.OemRevision);
        CFDictionaryAddValue(metadata, kMDItemVersion, item);
        CFRelease(item);
    }
    item = CFStringCreateByCombiningStrings(kCFAllocatorDefault, (__bridge CFArrayRef)StringsForAML(aml), CFSTR(" "));
    if (CFStringGetLength(item))
        CFDictionaryAddValue(metadata, kMDItemTextContent, item);
    CFRelease(item);
    return true;
}

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    // Pull any available metadata from the file at the specified path
    // Return the attribute keys and attribute values in the dict
    // Return TRUE if successful, FALSE if there was no data provided
	// The path could point to either a Core Data store file in which
	// case we import the store's metadata, or it could point to a Core
	// Data external record file for a specific record instances

    Boolean ok = FALSE;
    @autoreleasepool {
        
        if ([(__bridge NSString *)contentTypeUTI isEqualToString:@"org.acpica.aml"]) {
            // import from store file metadata
            
                // Get the information you are interested in from the dictionary
                // "YOUR_INFO" should be replaced by key(s) you are interested in
                
                ok = MetadataForAML([NSData dataWithContentsOfFile:(__bridge NSString *)pathToFile], attributes);
            
        } else if ([(__bridge NSString *)contentTypeUTI isEqualToString:@"net.sourceforge.maciasl.tableset"]) {
            // import from an external record file
            
            NSMutableArray *strings = [NSMutableArray array];
            NSDictionary *tables = [NSDictionary dictionaryWithContentsOfFile:(__bridge NSString *)pathToFile];
            CFDictionaryAddValue(attributes, kMDItemSubject, (__bridge CFStringRef)[tables objectForKey:@"Hostname"]);
            tables = [tables objectForKey:@"Tables"];
            for (NSString *table in tables) {
                [strings addObject:table];
                [strings addObjectsFromArray:StringsForAML([tables objectForKey:table])];
            }
            
            CFDictionaryAddValue(attributes, kMDItemTextContent, (__bridge CFStringRef)[strings componentsJoinedByString:@" "]);
            ok = TRUE;
        }
    }
    
	// Return the status
    return ok;
}
