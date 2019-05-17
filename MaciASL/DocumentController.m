//
//  DocumentController.m
//  MaciASL
//
//  Created by PHPdev32 on 10/14/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "DocumentController.h"
#import "Document.h"
#import "iASL.h"

@implementation DocumentController {
    @private
    __unsafe_unretained IBOutlet NSWindow *_tableView;
}

#pragma mark NSDocumentController
-(id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    id document;
    NSString *table;
    if ([typeName isEqualToString:kUTTypeTableset]) {
        if ((document = [self openTablesetTableWithContentsOfURL:url]))
            [self noteNewRecentDocumentURL:url];
    }
    else if ([typeName isEqualToString:kUTTypeIOJones]) {
        if ((document = [self openIOJonesTableWithContentsOfURL:url]))
            [self noteNewRecentDocumentURL:url];
    }
    else if ((table = [iASL isInjected:url])) {
        iASLDecompilationResult *decompile = [iASL decompileAML:[iASL fetchTable:table] name:table tableset:kSystemTableset refs:nil];
        if (!ModalError(decompile.error))
            [(document = [self newDocument:decompile.string displayName:nil tableName:table tableset:kSystemTableset display:false]) setFileURL:url];
    }
    else
        document = [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];
    if (!document && outError)
        *outError = [NSError errorWithDomain:kMaciASLDomain code:kTablesetError userInfo:nil];
    return document;
}

-(BOOL)presentError:(NSError *)error {
    if (error.code == kTablesetError && [error.domain isEqualToString:kMaciASLDomain]) return false;
    else return [super presentError:error];
}

#pragma mark Tableset
-(Document *)openTablesetTableWithContentsOfURL:(NSURL *)url {
    NSDictionary *tables = [NSDictionary dictionaryWithContentsOfURL:url];
    NSString *prefix = [[tables objectForKey:@"Hostname"] stringByAppendingString:@" "];
    tables = [tables objectForKey:@"Tables"];
    dispatch_sync(dispatch_get_main_queue(), ^{
        self->_tableView.titleWithRepresentedFilename = [url path];
        self->_tableView.representedURL = url;
    });
    NSMutableArray *tempNames = [NSMutableArray array], *tempTables = [NSMutableArray array];
    for (NSString *name in [tables.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
        NSString *type;
        if ([name hasPrefix:@"SSDT"])
            type = [[NSString alloc] initWithData:[[tables objectForKey:name] subdataWithRange:NSMakeRange(16, 8)] encoding:NSASCIIStringEncoding];
        [tempNames addObject:type ? [NSString stringWithFormat:@"%@ (%@)", name, type] : name];
        [tempTables addObject:name];
    }
    assignWithNotice(self, tableNames, [tempNames copy]);
    __block NSInteger modal;
    dispatch_sync(dispatch_get_main_queue(), ^{ modal = [NSApp runModalForWindow:self->_tableView]; });
    if (modal == NSRunAbortedResponse)
        return nil;
    else if (modal == NSRunStoppedResponse)
        tables = @{[tempTables objectAtIndex:_tableSelection]:[tables objectForKey:[tempTables objectAtIndex:_tableSelection]]};
    Document *document;
    modal = 0;
    for (NSString *table in tables) {
        modal++;
        iASLDecompilationResult *decompile = [iASL decompileAML:[tables objectForKey:table] name:table tableset:url refs:nil];
        if (!ModalError(decompile.error))
            document = [self newDocument:decompile.string displayName:[prefix stringByAppendingString:table] tableName:table tableset:url display:modal != tables.count];
    }
    return document;
}

-(Document *)openIOJonesTableWithContentsOfURL:(NSURL *)url {
    NSDictionary *tables = [NSDictionary dictionaryWithContentsOfURL:url];
    NSString *hostname = [(NSDictionary *)[tables objectForKey:@"system"] objectForKey:@"systemName"];
    for (NSDictionary *object in [tables objectForKey:@"objects"])
        if ([[object objectForKey:@"class"] isEqualToString:@"AppleACPIPlatformExpert"]) {
            tables = [(NSDictionary *)[object objectForKey:@"properties"] objectForKey:@"ACPI Tables"];
            break;
        }
    if (tables) {
        char *temp;
        mkdtemp(temp = strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:@"tableset.XXXXXX"] fileSystemRepresentation]));
        url = [(__bridge_transfer NSURL *)CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)temp, strlen(temp), true) URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.acpi", hostname]];
        free(temp);
        if ([@{@"Hostname":hostname, @"Tables":tables} writeToURL:url atomically:true])
            return [self openTablesetTableWithContentsOfURL:url];
    }
    else
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kTablesetError userInfo:@{NSLocalizedDescriptionKey:@"IOJones Error", NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"Could not find /AppleACPIPlatformExpert/ACPI Tables"]}]);
    return nil;
}

-(IBAction)finishTableset:(id)sender {
    if ([[sender title] isEqualToString:NSLocalizedString(@"cancel",@"Cancel")])
        [NSApp abortModal];
    else if ([[sender title] isEqualToString:NSLocalizedString(@"open-selected",@"Open Selected")])
        [NSApp stopModal];
    else
        [NSApp stopModalWithCode:NSModalResponseContinue];
    [_tableView orderOut:sender];
}

#pragma mark New Documents
-(Document *)newDocument:(NSString *)text displayName:(NSString *)displayName tableName:(NSString *)tableName tableset:(NSURL *)tableset display:(bool)display {
    NSError *err;
    Document *doc = [[Document alloc] initWithType:kUTTypeAML tableName:tableName tableset:tableset text:text error:&err];
    if (ModalError(err))
        return nil;
    doc.displayName = displayName;
    [self addDocument:doc];
    if (display) {
        [doc makeWindowControllers];
        [doc performSelectorOnMainThread:@selector(showWindows) withObject:nil waitUntilDone:true];
    }
    return doc;
}

-(Document *)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save {
    NSData *aml;
    if ((aml = [iASL fetchTable:name])) {
        NSURL *file = [iASL wasInjected:name];
        if (save && !file) {
            NSSavePanel *panel = [NSSavePanel savePanel];
            panel.prompt = NSLocalizedString(@"presave", @"Presave");
            panel.nameFieldStringValue = name;
            panel.allowedFileTypes = @[kUTTypeAML];
            if ([panel runModal] == NSFileHandlingPanelOKButton && [aml writeToURL:panel.URL atomically:true])
                file = panel.URL;
        }
        if (file && [[NSData dataWithContentsOfURL:file] isEqualToData:aml])
            [self openDocumentWithContentsOfURL:file display:true completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}];
        else {
            iASLDecompilationResult *decompile = [iASL decompileAML:aml name:name tableset:kSystemTableset refs:nil];
            if (!ModalError(decompile.error))
                return [self newDocument:decompile.string displayName:[NSString stringWithFormat:!file?@"System %@":@"Pre-Edited %@", name] tableName:name tableset:kSystemTableset display:true];
        }
    }
    return nil;
}

@end
