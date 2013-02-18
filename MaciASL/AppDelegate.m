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
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"theme":@"Light", @"dsdt":@(YES), @"suggest":@(NO), @"acpi":@4, @"context":@(NO), @"remarks":@(YES), @"optimizations": @(NO), @"werror": @(NO), @"preference": @0, @"font": @{@"name":@"Menlo", @"size": @11}, @"sources":@[@{@"name":@"Sourceforge", @"url":@"http://maciasl.sourceforge.net"}]}];
    [NSFontManager.sharedFontManager setTarget:self];
    NSDictionary *font = [NSUserDefaults.standardUserDefaults objectForKey:@"font"];
    [NSFontManager.sharedFontManager setSelectedFont:[NSFont fontWithName:[font objectForKey:@"name"] size:[[font objectForKey:@"size"] floatValue]] isMultiple:false];
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
}
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"dsdt"]) return true;
    [self newDocumentFromACPI:@"DSDT"];
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
    assignWithNotice(self, compiler, [lines componentsJoinedByString:@"\n"])
    [[NSDocumentController.sharedDocumentController documents] makeObjectsPerformSelector:@selector(compile:) withObject:self];
}

#pragma mark GUI
-(IBAction)showSSDT:(id)sender{
    [self.ssdt show:sender];
}
-(IBAction)swapPreference:(id)sender{
    [self viewPreference:sender];
}
-(IBAction)documentFromACPI:(id)sender{
    [self newDocumentFromACPI:[sender title]];
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
-(void)newDocumentFromACPI:(NSString *)name{
    NSString *file = [iASL wasInjected:name];
    if (file && [NSFileManager.defaultManager fileExistsAtPath:file] && [[NSFileManager.defaultManager contentsAtPath:file] isEqualToData:[iASL fetchTable:name]])
        [NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:file] display:true completionHandler:nil];
    else {
        NSDictionary *decompile = [iASL decompile:[iASL fetchTable:name]];
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
    switch (index) {
        case 0:
            [preferences setContentView:general];
            break;
        case 1:
            [preferences setContentView:iasl];
            break;
        case 2:
            [preferences setContentView:sources];
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