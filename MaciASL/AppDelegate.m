//
//  AppDelegate.m
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Source.h"
#import "AppDelegate.h"
#import "Colorize.h"
#import "iASL.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

@synthesize log;
@synthesize tables;
@synthesize compiler;
@synthesize general;
@synthesize iasl;
@synthesize sources;
@synthesize sourceView;
@synthesize sourceController;
@synthesize logView;
@synthesize summaryView;
@synthesize tableView;

#pragma mark Application Delegate
-(void)awakeFromNib{
    [FSDocumentController new];
    log = [NSMutableArray array];
    [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"acpi" options:0 context:NULL];
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"theme":@"Light", @"dsdt":@(YES), @"suggest":@(NO), @"acpi":@4, @"context":@(NO), @"isolation":@(NO), @"colorize":@(YES), @"remarks":@(YES), @"optimizations": @(NO), @"werror": @(NO), @"preference": @0, @"font": @{@"name":@"Menlo", @"size": @11}, @"sources":@[@{@"name":@"Sourceforge", @"url":@"http://maciasl.sourceforge.net"}]}];
    NSFontManager.sharedFontManager.target = self;
    NSDictionary *font = [NSUserDefaults.standardUserDefaults objectForKey:@"font"];
    [NSFontManager.sharedFontManager setSelectedFont:[NSFont fontWithName:[font objectForKey:@"name"] size:[[font objectForKey:@"size"] floatValue]] isMultiple:false];
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
    logView.level = NSNormalWindowLevel;
}
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"dsdt"]) return true;
    [FSDocumentController.sharedDocumentController newDocumentFromACPI:@"DSDT" saveFirst:false];
    return false;
}
-(SSDTGen *)ssdt{
    if (!_ssdt) _ssdt = [SSDTGen new];
    return _ssdt;
}
-(NSArray *)themes{
    return [[ColorTheme allThemes] allKeys];
}

#pragma mark Logging
-(void)logEntry:(NSString *)entry{
    muteWithNotice(self, log, [log addObject:[LogEntry create:entry]])
    [CATransaction flush];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    iASL *temp = [iASL new];
    temp.task = [NSTask create:[NSBundle.mainBundle pathForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl%ld", [NSUserDefaults.standardUserDefaults integerForKey:@"acpi"]]] args:@[] callback:NULL listener:nil];
    [temp.task launchAndWait];
    NSArray *lines = [[temp.stdOut componentsSeparatedByString:@"\n"] subarrayWithRange:NSMakeRange(0, 3)];
    for (NSString *line in lines) [self logEntry:line];
    self.compiler = [lines componentsJoinedByString:@"\n"];
    [[NSDocumentController.sharedDocumentController documents] makeObjectsPerformSelector:@selector(compile:) withObject:self];
}

#pragma mark GUI
-(IBAction)copy:(id)sender{
    NSResponder *obj = [[NSApp keyWindow] firstResponder];
    if (obj.class == NSTableView.class || obj.class == FSTableView.class) {
        if (![(NSTableView *)obj numberOfSelectedRows]) return;
        bool viewBased = ([(NSTableView *)obj rowViewAtRow:[(NSTableView *)obj selectedRow] makeIfNecessary:false]);
        __block NSMutableArray *rows = [NSMutableArray array];
        [[(NSTableView *)obj selectedRowIndexes] enumerateIndexesUsingBlock:^void(NSUInteger idx, BOOL *stop){
            NSUInteger i = 0, j = [(NSTableView *)obj numberOfColumns];
            NSMutableArray *row = [NSMutableArray array];
            if (viewBased) {
                NSText *view;
                while (i < j)
                    if ((view = [(NSTableView *)obj viewAtColumn:i++ row:idx makeIfNecessary:false]) && [view isKindOfClass:NSText.class])
                        [row addObject:[view.string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
            }
            else {
                NSCell *cell;
                while (i < j)
                    if ((cell = [(NSTableView *)obj preparedCellAtColumn:i++ row:idx]) && [cell isKindOfClass:NSTextFieldCell.class])
                        [row addObject:[cell.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
            }
            [row removeObject:@""];
            [rows addObject:[row componentsJoinedByString:@", "]];
        }];
        [NSPasteboard.generalPasteboard clearContents];
        [NSPasteboard.generalPasteboard writeObjects:@[[rows componentsJoinedByString:@"\n"]]];
    }
}
-(IBAction)showSSDT:(id)sender{
    [self.ssdt show:sender];
}
-(IBAction)swapPreference:(id)sender{
    [self viewPreference:sender];
}
-(IBAction)documentFromACPI:(id)sender{
    [FSDocumentController.sharedDocumentController newDocumentFromACPI:[sender title] saveFirst:NSEvent.modifierFlags&NSAlternateKeyMask];
}
-(IBAction)showLog:(id)sender{
    [logView makeKeyAndOrderFront:sender];
}
-(IBAction)showSummary:(id)sender{
    [summaryView makeKeyAndOrderFront:sender];
}
-(IBAction)update:(id)sender{//TODO: download progress?
    NSString *version = [[[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] componentsSeparatedByString:@"."] objectAtIndex:1];
    if ([URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%@/iasl4", version]] toFile:[NSBundle.mainBundle pathForAuxiliaryExecutable:@"iasl4"]] || [URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%@/iasl5", version]] toFile:[NSBundle.mainBundle pathForAuxiliaryExecutable:@"iasl5"]])
        [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
}
-(IBAction)newSource:(id)sender{
    [sourceController insertObject:sourceController.newObject atArrangedObjectIndex:0];
    [sourceView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    [sourceView editColumn:0 row:0 withEvent:nil select:true];
}
-(IBAction)exportTableset:(id)sender {
    NSSavePanel *save = [NSSavePanel savePanel];
    save.prompt = @"Export Tableset";
    save.nameFieldStringValue = NSHost.currentHost.localizedName;
    save.allowedFileTypes = @[kTablesetFileType];
    if ([save runModal] == NSFileHandlingPanelOKButton) {
        NSError *err;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:@{@"Hostname":NSHost.currentHost.localizedName, @"Tables":iASL.tableset} format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
        if (ModalError(err)) return;
        [NSFileManager.defaultManager createFileAtPath:save.URL.path contents:data attributes:nil];
    }
}
-(IBAction)openTableset:(id)sender {
    NSDictionary *tableset = [NSDictionary dictionaryWithContentsOfURL:sender], *tabs = [tableset objectForKey:@"Tables"];
    tableView.titleWithRepresentedFilename = [sender path];
    NSView *list = [tableView initialFirstResponder];
    [(NSPopUpButton *)list removeAllItems];
    [(NSPopUpButton *)list addItemsWithTitles:[tabs.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]];
    tableView.representedURL = sender;
    [NSApp runModalForWindow:tableView];
}
-(IBAction)finishTableset:(id)sender {
    [NSApp stopModal];
    [tableView orderOut:sender];
    if ([[sender title] isEqualToString:@"Cancel"]) return;
    NSDictionary *tableset = [NSDictionary dictionaryWithContentsOfURL:tableView.representedURL], *tabs = [tableset objectForKey:@"Tables"];
    NSString *prefix = [[tableset objectForKey:@"Hostname"] stringByAppendingString:@" "];
    if ([[sender title] isEqualToString:@"Open Selected"]) {
        sender = [(NSPopUpButton *)tableView.initialFirstResponder titleOfSelectedItem];
        tabs = @{sender:[tabs objectForKey:sender]};
    }
    for (NSString *table in tabs) {
        NSDictionary *decompile = [iASL decompile:[tabs objectForKey:table] withResolution:tableView.representedURL.path];
        if ([[decompile objectForKey:@"status"] boolValue])
            [FSDocumentController.sharedDocumentController newDocument:[decompile objectForKey:@"object"] withName:[prefix stringByAppendingString:table]];
        else
            ModalError([decompile objectForKey:@"object"]);
    }
}

#pragma mark Functions
-(void)viewPreference:(id)sender{
    NSWindow *preferences = [NSApp keyWindow];
    NSUInteger index;
    if (!sender) {
        index = [NSUserDefaults.standardUserDefaults integerForKey:@"preference"];
        sender = [preferences.toolbar.items objectAtIndex:index];
    }
    else {
        index = [preferences.toolbar.items indexOfObject:sender];
        if (index != NSNotFound)
            [NSUserDefaults.standardUserDefaults setInteger:index forKey:@"preference"];
    }
    NSSize newSize;
    switch (index) {
        case 0:
            newSize = general.frame.size;
            preferences.contentView = general;
            preferences.contentSize = newSize;
            break;
        case 1:
            newSize = iasl.frame.size;
            preferences.contentView = iasl;
            preferences.contentSize = newSize;
            break;
        case 2:
            newSize = sources.frame.size;
            preferences.contentView = sources;
            preferences.contentSize = newSize;
            break;
        default:
            return;
    }
    preferences.toolbar.selectedItemIdentifier = [sender itemIdentifier];
}
-(void)changeFont:(id)sender{
    NSFontManager *mgr = NSFontManager.sharedFontManager;
    NSFont *font = [mgr convertFont:[mgr selectedFont]];
    [NSUserDefaults.standardUserDefaults setObject:@{@"name":font.displayName, @"size":@(font.pointSize)} forKey:@"font"];
    muteWithNotice(mgr, selectedFont, [mgr setSelectedFont:font isMultiple:false])
}

#pragma mark NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    [[NSDocumentController.sharedDocumentController documentForWindow:[NSApp mainWindow]] tableViewSelectionDidChange:notification];
}
#pragma mark NSWindowDelegate
-(void)windowDidBecomeKey:(NSNotification *)notification{
    if ([[notification.object title] isEqualToString:@"Preferences"])
        [self viewPreference:nil];
}
@end

@implementation LogEntry

@synthesize timestamp;
@synthesize entry;

+(LogEntry *)create:(NSString *)entry{
    LogEntry *temp = [LogEntry new];
    temp.timestamp = [NSDate date];
    temp.entry = entry;
    return temp;
}

@end

@implementation FSDocumentController

#pragma mark NSDocumentController
-(id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    if (![typeName isEqualToString:kTablesetFileType]) return [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];
    [[NSApp delegate] openTableset:url];
    if (outError) *outError = [NSError errorWithDomain:kMaciASLDomain code:kTablesetError userInfo:nil];
    return nil;
}
-(BOOL)presentError:(NSError *)error {
    if (error.code == kTablesetError && [error.domain isEqualToString:kMaciASLDomain]) return false;
    else return [super presentError:error];
}

#pragma mark Functions
-(id)newDocument:(NSString *)text withName:(NSString *)name {
    NSError *err;
    Document *doc = [self openUntitledDocumentAndDisplay:false error:&err];
    if (ModalError(err)) return nil;
    doc.displayName = name;
    doc.text.mutableString.string = text;
    [doc makeWindowControllers];
    [doc performSelectorOnMainThread:@selector(showWindows) withObject:nil waitUntilDone:false];
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
            return [self newDocument:[decompile objectForKey:@"object"] withName:[NSString stringWithFormat:!file?@"System %@":@"Pre-Edited %@", name]];
        else
            ModalError([decompile objectForKey:@"object"]);
    }
    return nil;
}


@end

@implementation FSTableView

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent{
    return true;
}

@end

@implementation FSPanel

-(BOOL)becomesKeyOnlyIfNeeded{
    return true;
}

@end

@implementation FSTextView

-(void)scrollRangeToVisible:(NSRange)range{
    [super scrollRangeToVisible:range];
    if (!NSEqualRanges(range, self.selectedRange) && [[[NSTextFinder class] performSelector:@selector(_globalTextFinder)] client] == (id)self && [self.delegate respondsToSelector:@selector(textViewDidShowFindIndicator:)])
        [self.delegate performSelector:@selector(textViewDidShowFindIndicator:) withObject:[NSNotification notificationWithName:@"NSTextViewDidShowFindIndicatorNotification" object:self userInfo:@{@"NSFindIndicatorRange":[NSValue valueWithRange:range]}]];
}

@end

@implementation FSRulerView
static NSDictionary *style;

+(void)initialize {
    NSMutableParagraphStyle *temp = [NSMutableParagraphStyle new];
    temp.alignment = NSRightTextAlignment;
    style = @{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.smallSystemFontSize], NSParagraphStyleAttributeName:[temp copy]};
}
-(id)init {
    self = [super init];
    if (self) {
        super.reservedThicknessForMarkers = 0;
    }
    return self;
}
-(void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    NSInteger height = [[self.scrollView.documentView layoutManager] defaultLineHeightForFont:NSFontManager.sharedFontManager.selectedFont], start = floor((self.scrollView.documentVisibleRect.origin.y+rect.origin.y)/height)+1, stop = 1+start+ceil(rect.size.height/height);
    if (self.ruleThickness < MAX(16,((NSInteger)log10(stop)+1)*8)) {
        self.ruleThickness = ((NSInteger)log10(stop)+1)*8;
        return;
    }
    rect.size.width -= 2;
    rect.origin.y -= (NSInteger)(self.scrollView.documentVisibleRect.origin.y+rect.origin.y) % height - (height-(NSFont.smallSystemFontSize+2))/2;
    rect.size.height = height;
    while (start < stop) {
        [[NSString stringWithFormat:@"%ld", start++] drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:style];
        rect.origin.y += height;
    }
}

@end
