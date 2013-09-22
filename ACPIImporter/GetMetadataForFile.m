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
        NSError *error = nil;
        
        if ([(__bridge NSString *)contentTypeUTI isEqualToString:@"org.acpica.aml"]) {
            // import from store file metadata
            
            // Create the URL, then attempt to get the meta-data from the store
            NSURL *url = [NSURL fileURLWithPath:(__bridge NSString *)pathToFile];
            
            // If there is no error, add the info
            if (error == NULL) {
                // Get the information you are interested in from the dictionary
                // "YOUR_INFO" should be replaced by key(s) you are interested in
                
                NSArray *contentToIndex = StringsForAML([NSData dataWithContentsOfURL:url]);
                if (contentToIndex != nil) {
                    // Add the metadata to the text content for indexing
                    ((__bridge NSMutableDictionary *)attributes)[(NSString *)kMDItemTextContent] = [contentToIndex componentsJoinedByString:@" "];
                    ok = TRUE;
                }
            }
            
        } else if ([(__bridge NSString *)contentTypeUTI isEqualToString:@"net.sourceforge.maciasl.tableset"]) {
            // import from an external record file
            
            NSMutableArray *strings = [NSMutableArray array];
            NSDictionary *tables = [[NSDictionary dictionaryWithContentsOfFile:(__bridge NSString *)pathToFile] objectForKey:@"Tables"];
            for (NSString *table in tables) {
                [strings addObject:table];
                [strings addObjectsFromArray:StringsForAML([tables objectForKey:table])];
            }
            
            ((__bridge NSMutableDictionary *)attributes)[(NSString *)kMDItemTextContent] = [strings componentsJoinedByString:@" "];
            ok = TRUE;
        }
    }
    
	// Return the status
    return ok;
}
