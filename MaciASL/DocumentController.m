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

@implementation DocumentController

@synthesize tableView;

#pragma mark NSDocumentController
-(id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    id document;
    if ([typeName isEqualToString:kUTTypeTableset])
        document = [self openTableset:url];
    else if ([typeName isEqualToString:kUTTypeIOJones])
        document = [self openIOJones:url];
    else
        return [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];
    if (!document && outError)
        *outError = [NSError errorWithDomain:kMaciASLDomain code:kTablesetError userInfo:nil];
    return document;
}
-(BOOL)presentError:(NSError *)error {
    if (error.code == kTablesetError && [error.domain isEqualToString:kMaciASLDomain]) return false;
    else return [super presentError:error];
}

#pragma mark Tableset
-(id)openTableset:(id)sender {
    NSDictionary *tabs = [NSDictionary dictionaryWithContentsOfURL:sender];
    NSString *prefix = [[tabs objectForKey:@"Hostname"] stringByAppendingString:@" "];
    tabs = [tabs objectForKey:@"Tables"];
    tableView.titleWithRepresentedFilename = [sender path];
    tableView.representedURL = sender;
    NSMenu *menu = [(NSPopUpButton *)tableView.initialFirstResponder menu];
    [menu removeAllItems];
    for (NSString *name in [tabs.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
        NSMenuItem *item;
        if ([name hasPrefix:@"SSDT"]) {
            NSString *type = [[NSString alloc] initWithData:[[tabs objectForKey:name] subdataWithRange:NSMakeRange(16, 8)] encoding:NSASCIIStringEncoding];
            item = [[NSMenuItem alloc] initWithTitle:type ? [NSString stringWithFormat:@"%@ (%@)", name, type] : name action:NULL keyEquivalent:@""];
        }
        else
            item = [[NSMenuItem alloc] initWithTitle:name action:NULL keyEquivalent:@""];
        item.representedObject = name;
        [menu addItem:item];
    }
    NSInteger modal = [NSApp runModalForWindow:tableView];
    sender = [[(NSPopUpButton *)tableView.initialFirstResponder selectedItem] representedObject];
    if (modal == NSRunAbortedResponse)
        return nil;
    else if (modal == NSRunStoppedResponse)
        tabs = @{sender:[tabs objectForKey:sender]};
    Document *document;
    modal = 0;
    for (NSString *table in tabs) {
        modal++;
        NSDictionary *decompile = [iASL decompile:[tabs objectForKey:table] withResolution:tableView.representedURL.path];
        if ([[decompile objectForKey:@"status"] boolValue])
            document = [self newDocument:[decompile objectForKey:@"object"] withName:[prefix stringByAppendingString:table] display:modal != tabs.count];
        else
            ModalError([decompile objectForKey:@"object"]);
    }
    return document;
}
-(id)openIOJones:(id)sender {
    NSDictionary *tabs = [NSDictionary dictionaryWithContentsOfURL:sender];
    NSString *hostname = [[tabs objectForKey:@"system"] objectForKey:@"systemName"];
    for (NSDictionary *object in [tabs objectForKey:@"objects"])
        if ([[object objectForKey:@"class"] isEqualToString:@"AppleACPIPlatformExpert"]) {
            tabs = [[object objectForKey:@"properties"] objectForKey:@"ACPI Tables"];
            break;
        }
    if (!tabs) return nil;
    char *template = (char *)[[NSTemporaryDirectory() stringByAppendingPathComponent:@"tableset.XXXXXX"] fileSystemRepresentation];
    NSURL *path = [[NSURL fileURLWithPath:[NSFileManager.defaultManager stringWithFileSystemRepresentation:mkdtemp(template) length:strlen(template)]] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.acpi", hostname]];
    if ([@{@"Hostname":hostname, @"Tables":tabs} writeToURL:path atomically:true])
        return [self openTableset:path];
    else
        return nil;
}
-(IBAction)finishTableset:(id)sender {
    if ([[sender title] isEqualToString:@"Cancel"])
        [NSApp abortModal];
    else if ([[sender title] isEqualToString:@"Open Selected"])
        [NSApp stopModal];
    else
        [NSApp stopModalWithCode:NSRunContinuesResponse];
    [tableView orderOut:sender];
}

#pragma mark New Documents
-(id)newDocument:(NSString *)text withName:(NSString *)name display:(bool)display {
    NSError *err;
    Document *doc = [self openUntitledDocumentAndDisplay:false error:&err];
    if (ModalError(err)) return nil;
    doc.displayName = name;
    doc.text.mutableString.string = text;
    if (display) {
        [doc makeWindowControllers];
        [doc performSelectorOnMainThread:@selector(showWindows) withObject:nil waitUntilDone:true];
    }
    return doc;
}
-(id)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save {
    NSString *file = [iASL wasInjected:name];
    NSData *aml;
    if (!(aml = [iASL fetchTable:name])) return nil;
    if (save && !file) {
        NSSavePanel *save = [NSSavePanel savePanel];
        save.prompt = @"Presave";
        save.nameFieldStringValue = name;
        save.allowedFileTypes = @[kUTTypeAML];
        if ([save runModal] == NSFileHandlingPanelOKButton && [NSFileManager.defaultManager createFileAtPath:save.URL.path contents:aml attributes:nil])
            file = save.URL.path;
    }
    if (file && [NSFileManager.defaultManager fileExistsAtPath:file] && [[NSFileManager.defaultManager contentsAtPath:file] isEqualToData:aml])
        [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:file] display:true completionHandler:nil];
    else {
        NSDictionary *decompile = [iASL decompile:aml withResolution:kSystemTableset];
        if ([[decompile objectForKey:@"status"] boolValue])
            return [self newDocument:[decompile objectForKey:@"object"] withName:[NSString stringWithFormat:!file?@"System %@":@"Pre-Edited %@", name] display:true];
        else
            ModalError([decompile objectForKey:@"object"]);
    }
    return nil;
}

@end
