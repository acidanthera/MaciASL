//
//  AppDelegate.m
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "AppDelegate.h"
#import "Source.h"
#import "Document.h"
#import "Colorize.h"
#import "iASL.h"
#import "SSDT.h"
#import "DocumentController.h"
#import <sys/sysctl.h>
#import <sys/types.h>

@interface LogEntry : NSObject

@property NSDate *timestamp;
@property NSString *entry;

@end

@implementation LogEntry

-(instancetype)initWithEntry:(NSString *)entry {
    self = [super init];
    if (self) {
        _timestamp = [NSDate date];
        _entry = entry;
    }
    return self;
}

@end

@implementation AppDelegate {
    @private
    NSMutableArray *_log;
    __unsafe_unretained IBOutlet NSView *_general, __unsafe_unretained *_iasl, __unsafe_unretained *_sources;
    __unsafe_unretained IBOutlet NSWindow *_logView, __unsafe_unretained *_summaryView;
    __unsafe_unretained IBOutlet NSTableView *_sourceView;
    __unsafe_unretained IBOutlet NSArrayController *_sourceController;
}

#pragma mark Application Delegate
-(void)awakeFromNib {
    _log = [NSMutableArray array];
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"theme":@"Light", @"dsdt":@(YES), @"suggest":@(NO), @"acpi":@4, @"context":@(NO), @"isolation":@(NO), @"colorize":@(YES), @"remarks":@(NO), @"optimizations": @(NO), @"werror": @(NO), @"preference": @0, @"font": @{@"name":@"Menlo", @"size": @11}, @"sources":@[@{@"name":@"Sourceforge", @"url":@"http://maciasl.sourceforge.net"}, @{@"name":@"Gigabyte", @"url":@"http://maciasl.sourceforge.net/pjalm/gigabyte"}, @{@"name":@"ASUS", @"url":@"http://maciasl.sourceforge.net/pjalm/asus"}]}];
    NSFontManager.sharedFontManager.target = self;
    NSDictionary *font = [NSUserDefaults.standardUserDefaults objectForKey:@"font"];
    [NSFontManager.sharedFontManager setSelectedFont:[NSFont fontWithName:[font objectForKey:@"name"] size:[[font objectForKey:@"size"] floatValue]] isMultiple:false];
    _logView.level = NSNormalWindowLevel;
    [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"acpi" options:NSKeyValueObservingOptionInitial context:NULL];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"dsdt"])
        return true;
    [DocumentController.sharedDocumentController newDocumentFromACPI:@"DSDT" saveFirst:false];
    return false;
}


#pragma mark Logging
-(void)logEntry:(NSString *)entry {
    insertWithNotice(self, log, [[LogEntry alloc] initWithEntry:entry])
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSMutableData *d = [NSMutableData data];
    NSTask *t = [NSTask new];
    t.launchPath = [NSBundle.mainBundle pathForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl%ld", [NSUserDefaults.standardUserDefaults integerForKey:@"acpi"]]];
    t.standardOutput = [NSPipe pipe];
    [[t.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *h) { [d appendData:h.availableData]; }];
    @try { [t launch]; }
    @catch (NSException *e) { [self logEntry:[NSString stringWithFormat:@"Could not launch %@", t.launchPath]]; return; }
    [t waitUntilExit];
    NSArray *lines = [[[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"] subarrayWithRange:NSMakeRange(0, 3)];
    for (NSString *line in lines)
        [self logEntry:line];
    assignWithNotice(self, compiler, [lines componentsJoinedByString:@"\n"]);
    for (Document *doc in [NSDocumentController.sharedDocumentController documents])
        if (!doc.isDocumentEdited)
            [doc revertToContentsOfURL:doc.fileURL ofType:doc.fileType error:NULL];
}

#pragma mark Actions
-(IBAction)copy:(id)sender {
    NSResponder *obj = [[NSApp keyWindow] firstResponder];
    if (obj.class == NSTableView.class || obj.class == FSTableView.class || obj.class == NSOutlineView.class) {
        if (![(NSTableView *)obj numberOfSelectedRows]) return;
        bool viewBased = ([(NSTableView *)obj rowViewAtRow:[(NSTableView *)obj selectedRow] makeIfNecessary:false]);
        NSMutableArray *rows = [NSMutableArray array];
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

-(IBAction)swapPreference:(id)sender {
    [self viewPreference:sender];
}

-(IBAction)documentFromACPI:(id)sender {
    [DocumentController.sharedDocumentController newDocumentFromACPI:[sender title] saveFirst:NSEvent.modifierFlags&NSAlternateKeyMask];
}

-(IBAction)showLog:(id)sender {
    [_logView makeKeyAndOrderFront:sender];
}

-(IBAction)showSummary:(id)sender {
    [_summaryView makeKeyAndOrderFront:sender];
}

-(IBAction)update:(id)sender {
    NSString *version = [[[(NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] componentsSeparatedByString:@"."] objectAtIndex:1];
    [sender setEnabled:false];
    void(^handler)(bool) = ^(bool success){
        if (success)
            [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
        [sender setEnabled:true];
    };
    [URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%@/iasl4", version]] toURL:[NSBundle.mainBundle URLForAuxiliaryExecutable:@"iasl4"] perform:handler];
    [URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%@/iasl5", version]] toURL:[NSBundle.mainBundle URLForAuxiliaryExecutable:@"iasl5"] perform:handler];
    [URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%@/iasl51", version]] toURL:[NSBundle.mainBundle URLForAuxiliaryExecutable:@"iasl51"] perform:handler];
}

-(IBAction)newSource:(id)sender {
    [_sourceController insertObject:_sourceController.newObject atArrangedObjectIndex:0];
    [_sourceView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    [_sourceView editColumn:0 row:0 withEvent:nil select:true];
}

-(IBAction)exportTableset:(id)sender {
    NSSavePanel *save = [NSSavePanel savePanel];
    save.prompt = @"Export Tableset";
    save.nameFieldStringValue = NSHost.currentHost.localizedName;
    save.allowedFileTypes = @[kUTTypeTableset];
    if ([save runModal] == NSFileHandlingPanelOKButton) {
        NSError *err;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:@{@"Hostname":NSHost.currentHost.localizedName, @"Tables":iASL.tableset} format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
        if (ModalError(err)) return;
        [data writeToURL:save.URL atomically:true];
    }
}

#pragma mark Readonly Properties
-(NSArray *)deviceProperties {
    return iASL.deviceProperties;
}

-(NSArray *)log {
    return [_log copy];
}

-(NSArray *)themes {
    return ColorTheme.allThemes.allKeys;
}

#pragma mark Functions
-(void)viewPreference:(id)sender {
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
            newSize = _general.frame.size;
            preferences.contentView = _general;
            preferences.contentSize = newSize;
            break;
        case 1:
            newSize = _iasl.frame.size;
            preferences.contentView = _iasl;
            preferences.contentSize = newSize;
            break;
        case 2:
            newSize = _sources.frame.size;
            preferences.contentView = _sources;
            preferences.contentSize = newSize;
            break;
        default:
            return;
    }
    preferences.toolbar.selectedItemIdentifier = [sender itemIdentifier];
}

-(void)changeFont:(id)sender {
    NSFontManager *manager = NSFontManager.sharedFontManager;
    NSFont *font = [manager convertFont:[manager selectedFont]];
    [NSUserDefaults.standardUserDefaults setObject:@{@"name":font.displayName, @"size":@(font.pointSize)} forKey:@"font"];
    muteWithNotice(manager, selectedFont, [manager setSelectedFont:font isMultiple:false])
}

#pragma mark NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [[NSDocumentController.sharedDocumentController documentForWindow:[NSApp mainWindow]] tableViewSelectionDidChange:notification];
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSInteger rows = outlineView.tableColumns.count, row = [outlineView rowForItem:item];
    CGFloat height = outlineView.rowHeight;
    while (rows-- > 0)
        height = MAX([[outlineView preparedCellAtColumn:rows row:row] cellSizeForBounds:NSMakeRect(0, 0, [[outlineView.tableColumns objectAtIndex:rows] width], CGFLOAT_MAX)].height,height);
    return height;
}

#pragma mark NSWindowDelegate
-(void)windowDidBecomeKey:(NSNotification *)notification {
    if ([notification.object isMemberOfClass:NSWindow.class])
        [self viewPreference:nil];
}
@end

@implementation FSTableView

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return true;
}

@end

@implementation FSPanel

-(BOOL)becomesKeyOnlyIfNeeded {
    return true;
}

@end

@interface NSTextFinder ()

+(NSTextFinder *)_globalTextFinder;

@end

@implementation FSTextView

-(void)scrollRangeToVisible:(NSRange)range {
    [super scrollRangeToVisible:range];
    if (!NSEqualRanges(range, self.selectedRange)
        && NSTextFinder._globalTextFinder.client == (id)self
        && [self.delegate conformsToProtocol:@protocol(NSTextFinderIndication)])
        [(id<NSTextFinderIndication>)self.delegate textViewDidShowFindIndicator:[NSNotification notificationWithName:@"NSTextViewDidShowFindIndicatorNotification" object:self userInfo:@{@"NSFindIndicatorRange":[NSValue valueWithRange:range]}]];
}

@end

@implementation FSRulerView
static NSDictionary *style;

+(void)load {
    NSMutableParagraphStyle *temp = [NSMutableParagraphStyle new];
    temp.alignment = NSRightTextAlignment;
    style = @{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.smallSystemFontSize], NSParagraphStyleAttributeName:[temp copy]};
}

-(instancetype)init {
    self = [super init];
    if (self)
        super.reservedThicknessForMarkers = 0;
    return self;
}

-(void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    NSInteger height = (NSInteger)[[(NSTextView *)self.scrollView.documentView layoutManager] defaultLineHeightForFont:NSFontManager.sharedFontManager.selectedFont], start = (NSInteger)floor((self.scrollView.documentVisibleRect.origin.y + rect.origin.y) / height) + 1, stop = 1 + start + (NSInteger)ceil(rect.size.height / height);
    if (self.ruleThickness < MAX(16,((NSInteger)log10(stop)+1)*8)) {
        self.ruleThickness = ((NSInteger)log10(stop)+1)*8;
        return;
    }
    rect.size.width -= 2;
    rect.origin.y -= (NSInteger)(self.scrollView.documentVisibleRect.origin.y+rect.origin.y) % height - (height-(NSFont.smallSystemFontSize+2))/2 + 1;
    rect.size.height = height;
    while (start < stop) {
        [[NSString stringWithFormat:@"%ld", start++] drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:style];
        rect.origin.y += height;
    }
}

@end
