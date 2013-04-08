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

#pragma mark Application Delegate
-(void)awakeFromNib{
    log = [NSMutableArray array];
    [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"acpi" options:0 context:NULL];
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"theme":@"Light", @"dsdt":@(YES), @"suggest":@(NO), @"acpi":@4, @"context":@(NO), @"isolation":@(NO), @"colorize":@(YES), @"remarks":@(YES), @"optimizations": @(NO), @"werror": @(NO), @"preference": @0, @"font": @{@"name":@"Menlo", @"size": @11}, @"sources":@[@{@"name":@"Sourceforge", @"url":@"http://maciasl.sourceforge.net"}]}];
    [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"colorize" options:0 context:NULL];
    [NSFontManager.sharedFontManager setTarget:self];
    NSDictionary *font = [NSUserDefaults.standardUserDefaults objectForKey:@"font"];
    [NSFontManager.sharedFontManager setSelectedFont:[NSFont fontWithName:[font objectForKey:@"name"] size:[[font objectForKey:@"size"] floatValue]] isMultiple:false];
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
    [logView setLevel:NSNormalWindowLevel];
}
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"dsdt"]) return true;
    [self newDocumentFromACPI:@"DSDT" saveFirst:false];
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
    if ([keyPath isEqualToString:@"acpi"])
        [self acpiDidChangeTo:[object integerForKey:keyPath]];
    else if ([keyPath isEqualToString:@"colorize"])
        [self colorizeDidChange:[object objectForKey:keyPath]];
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
    [self newDocumentFromACPI:[sender title] saveFirst:[[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask];
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

#pragma mark Functions
-(void)colorizeDidChange:(NSNumber *)value {
    [[NSDocumentController.sharedDocumentController documents] makeObjectsPerformSelector:@selector(colorizeDidChange:) withObject:value];
}
-(void)acpiDidChangeTo:(NSInteger)acpi {
    iASL *temp = [iASL new];
    temp.task = [NSTask create:[NSBundle.mainBundle pathForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl%ld", acpi]] args:@[] callback:NULL listener:nil];
    [temp.task launchAndWait];
    NSArray *lines = [[temp.stdOut componentsSeparatedByString:@"\n"] subarrayWithRange:NSMakeRange(0, 3)];
    for (NSString *line in lines) [self logEntry:line];
    self.compiler = [lines componentsJoinedByString:@"\n"];
    [[NSDocumentController.sharedDocumentController documents] makeObjectsPerformSelector:@selector(compile:) withObject:self];
}
-(void)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save{
    NSString *file = [iASL wasInjected:name];
    NSData *aml;
    if (!(aml = [iASL fetchTable:name])) return;
    if (save && !file) {
        NSSavePanel *save = [NSSavePanel savePanel];
        save.prompt = @"Presave";
        save.nameFieldStringValue = name;
        save.allowedFileTypes = @[kAMLfileType];
        if ([save runModal] == NSFileHandlingPanelOKButton && [NSFileManager.defaultManager createFileAtPath:save.URL.path contents:aml attributes:nil])
            file = save.URL.path;
    }
    if (file && [NSFileManager.defaultManager fileExistsAtPath:file] && [[NSFileManager.defaultManager contentsAtPath:file] isEqualToData:aml])
        [NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:file] display:true completionHandler:nil];
    else {
        NSDictionary *decompile = [iASL decompile:aml];
        if ([[decompile objectForKey:@"status"] boolValue])
            [self newDocument:[decompile objectForKey:@"object"] withName:[NSString stringWithFormat:!file?@"System %@":@"Pre-Edited %@", name]];
        else
            ModalError([decompile objectForKey:@"object"]);
    }
}
-(Document *)newDocument:(NSString *)text withName:(NSString *)name{
    NSError *err;
    Document *doc = [NSDocumentController.sharedDocumentController openUntitledDocumentAndDisplay:true error:&err];
    if (ModalError(err)) return nil;
    [[[doc.windowControllers objectAtIndex:0] window] setTitle:name];
    [doc setDocument:text];
    [doc.textView setSelectedRange:NSMakeRange(0, 0)];
    return doc;
}
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
            [preferences setContentView:general];
            [preferences setContentSize:newSize];
            break;
        case 1:
            newSize = iasl.frame.size;
            [preferences setContentView:iasl];
            [preferences setContentSize:newSize];
            break;
        case 2:
            newSize = sources.frame.size;
            [preferences setContentView:sources];
            [preferences setContentSize:newSize];
            break;
        default:
            return;
    }
    [preferences.toolbar setSelectedItemIdentifier:[sender itemIdentifier]];
}
-(void)changeFont:(id)sender{
    NSFontManager *mgr = NSFontManager.sharedFontManager;
    NSFont *font = [mgr convertFont:[mgr selectedFont]];
    [NSUserDefaults.standardUserDefaults setObject:@{@"name":font.displayName, @"size":@(font.pointSize)} forKey:@"font"];
    muteWithNotice(mgr, selectedFont, [mgr setSelectedFont:font isMultiple:false])
    [[NSDocumentController.sharedDocumentController documents] makeObjectsPerformSelector:@selector(changeRuler)];
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