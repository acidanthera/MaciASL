//
//  GetMetadataForFile.m
//  ACPIImporter
//
//  Created by PHPdev32 on 9/17/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#include <CoreServices/CoreServices.h>

/*! \brief Parses a ReadStream for AML strings
 *
 * \param stream The ReadStream representing an AML file
 * \returns An Array of Strings found in the stream
 */
CFArrayRef CFArrayCreateWithAML(CFReadStreamRef stream) {
    UInt8 i;
    CFMutableSetRef strings = NULL;
    while (CFReadStreamGetStatus(stream) < kCFStreamStatusAtEnd) {
        while (CFReadStreamRead(stream, &i, 1) == 1 && i != 0x0D)
            ;
        CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
        while (CFReadStreamRead(stream, &i, 1) == 1 && i < 0x7F && i > 0x19)
            CFDataAppendBytes(data, &i, 1);
        if (i == 0 && CFDataGetLength(data) > 2) {
            if (!strings)
                strings = CFSetCreateMutable(kCFAllocatorDefault, 0, &kCFTypeSetCallBacks);
            CFStringRef string = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(data), CFDataGetLength(data), kCFStringEncodingASCII, false);
            CFSetAddValue(strings, string);
            CFRelease(string);
        }
        CFRelease(data);
    }
    if (strings) {
        CFTypeRef values[CFSetGetCount(strings)];
        CFSetGetValues(strings, values);
        CFArrayRef array = CFArrayCreate(kCFAllocatorDefault, values, sizeof(values)/sizeof(*values), &kCFTypeArrayCallBacks);
        CFRelease(strings);
        return array;
    }
    else
        return NULL;
}

/*! \brief Appends metadata found in an AML ReadStream to the given MutableDictionary
 *
 * \param aml A ReadStream representing an AML file
 * \param metadata A Spotlight metadata dictionary
 * \returns A boolean representing the success of the call
 */
bool CFDictionaryAppendMetadataWithAML(CFReadStreamRef aml, CFMutableDictionaryRef metadata) {
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
    CFReadStreamRead(aml, (UInt8 *)&header, sizeof(header));
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
    CFArrayRef strings = CFArrayCreateWithAML(aml);
    if (strings) {
        item = CFStringCreateByCombiningStrings(kCFAllocatorDefault, strings, CFSTR(" "));
        CFRelease(strings);
        if (CFStringGetLength(item))
            CFDictionaryAddValue(metadata, kMDItemTextContent, item);
        CFRelease(item);
    }
    return true;
}

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

//==============================================================================
//
//  Get metadata attributes from document files
//
//  The purpose of this function is to extract useful information from the
//  file formats for your document, and set the values into the attribute
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
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, pathToFile, kCFURLPOSIXPathStyle, false);
    CFReadStreamRef stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, url);
    CFRelease(url);
    CFReadStreamOpen(stream);
    
    if (CFStringCompare(contentTypeUTI, CFSTR("org.acpica.aml"), 0) == kCFCompareEqualTo) {
        // import from store file metadata
        
        // Get the information you are interested in from the dictionary
        // "YOUR_INFO" should be replaced by key(s) you are interested in
        
        ok = CFDictionaryAppendMetadataWithAML(stream, attributes);
        
    } else if (CFStringCompare(contentTypeUTI, CFSTR("net.sourceforge.maciasl.tableset"), 0) == kCFCompareEqualTo) {
        // import from an external record file
        
        CFPropertyListRef set = CFPropertyListCreateWithStream(kCFAllocatorDefault, stream, 0, kCFPropertyListImmutable, NULL, NULL);
        if (set != nil && CFGetTypeID(set) == CFDictionaryGetTypeID()) {
            CFDictionaryAddValue(attributes, kMDItemSubject, CFDictionaryGetValue(set, CFSTR("Hostname")));
            CFDictionaryRef tables = CFDictionaryGetValue(set, CFSTR("Tables"));
            CFIndex i = 0, j = CFDictionaryGetCount(tables);
            CFTypeRef keys[j], values[j];
            CFDictionaryGetKeysAndValues(tables, keys, values);
            CFMutableArrayRef strings = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
            while (i < j) {
                CFArrayAppendValue(strings, keys[i]);
                CFReadStreamRef data = CFReadStreamCreateWithBytesNoCopy(kCFAllocatorDefault, CFDataGetBytePtr(values[i]), CFDataGetLength(values[i]), kCFAllocatorNull);
                CFReadStreamOpen(data);
                CFArrayRef array = CFArrayCreateWithAML(data);
                if (array) {
                    CFArrayAppendArray(strings, array, CFRangeMake(0, CFArrayGetCount(array)));
                    CFRelease(array);
                }
                CFReadStreamClose(data);
                CFRelease(data);
                i++;
            }
            CFStringRef string = CFStringCreateByCombiningStrings(kCFAllocatorDefault, strings, CFSTR(" "));
            CFRelease(strings);
            CFDictionaryAddValue(attributes, kMDItemTextContent, string);
            CFRelease(string);
            ok = TRUE;
        }
        CFRelease(set);
    }
    CFReadStreamClose(stream);
    CFRelease(stream);
    
    // Return the status
    return ok;
}
