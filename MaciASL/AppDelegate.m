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
    [NSUserDefaults.standardUserDefaults registerDefaults:
    @{
      @"theme": @"Light",
      @"dsdt": @(YES),
      @"suggest": @(NO),
      @"acpi": @62,
      @"context": @(NO),
      @"isolation": @(NO),
      @"colorize": @(YES),
      @"remarks": @(NO),
      @"optimizations": @(NO),
      @"werror": @(NO),
      @"autoloadtables": @(NO),
      @"extracomp": @"",
      @"extradecomp": @"",
      @"preference": @0,
      @"font": @{@"name": @"Menlo", @"size": @11},
      @"sources": @[
        @{@"name": @"Sourceforge", @"url": @"http://maciasl.sourceforge.net"},
        @{@"name": @"Gigabyte", @"url": @"http://maciasl.sourceforge.net/pjalm/gigabyte"},
        @{@"name": @"ASUS", @"url": @"http://maciasl.sourceforge.net/pjalm/asus"},
        @{@"name": @"MSI", @"url": @"http://maciasl.sourceforge.net/pjalm/msi"},
        @{@"name": @"ASRock", @"url": @"http://maciasl.sourceforge.net/pjalm/asrock"},
        @{@"name": @"Zotac", @"url": @"http://maciasl.sourceforge.net/pjalm/zotac"},
        @{@"name": @"General", @"url": @"http://maciasl.sourceforge.net/pjalm/general"},
        @{@"name": @"Graphics", @"url": @"http://maciasl.sourceforge.net/pjalm/graphics"},
        @{@"name": @"Intel Series 6", @"url": @"http://maciasl.sourceforge.net/pjalm/intel6"},
        @{@"name": @"Intel Series 7", @"url": @"http://maciasl.sourceforge.net/pjalm/intel7"},
        @{@"name": @"Intel Series 8", @"url": @"http://maciasl.sourceforge.net/pjalm/intel8"},
        @{@"name": @"Intel Series 9", @"url": @"http://maciasl.sourceforge.net/pjalm/intel9"},
        @{@"name": @"Rehabman", @"url": @"http://raw.github.com/RehabMan/Laptop-DSDT-Patch/master"},
        @{@"name": @"Toleda HDMI", @"url": @"http://raw.github.com/toleda/audio_hdmi_uefi/master"},
        @{@"name": @"Toleda HDMI 8", @"url": @"http://raw.github.com/toleda/audio_hdmi_8series/master"},
        @{@"name": @"Toleda ALC", @"url": @"http://raw.github.com/toleda/audio_ALCInjection/master"},
    ]}];
    NSFontManager.sharedFontManager.target = self;
    NSDictionary *font = [NSUserDefaults.standardUserDefaults objectForKey:@"font"];
    [NSFontManager.sharedFontManager setSelectedFont:[NSFont fontWithName:[font objectForKey:@"name"] size:[[font objectForKey:@"size"] floatValue]] isMultiple:false];
    _logView.level = NSNormalWindowLevel;
    [iASL addObserver:self forKeyPath:@"compiler" options:0 context:NULL];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"dsdt"])
        return true;
    [DocumentController.sharedDocumentController newDocumentFromACPI:@"DSDT" saveFirst:false];
    return false;
}


#pragma mark Logging
-(void)logEntry:(NSString *)entry {
    if (NSThread.isMainThread) {
        insertWithNotice(self, log, [[LogEntry alloc] initWithEntry:entry])
    }
    else
        [self performSelectorOnMainThread:_cmd withObject:entry waitUntilDone:false];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    muteWithNotice(self, compiler,);
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
    [sender setEnabled:false];
    NSString *os = [[[(NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] componentsSeparatedByString:@"."] objectAtIndex:1];
    int osmajor = [os intValue];
    if (osmajor > 11) osmajor = 11;
    muteWithNotice(self, update, _update = [NSProgress progressWithTotalUnitCount:3]);
    dispatch_group_t g = dispatch_group_create();
    for (NSNumber *iasl in @[@4, @5, @51, @6]) {
        [_update becomeCurrentWithPendingUnitCount:1];
        dispatch_group_enter(g);
        [URLTask conditionalGet:[NSURL URLWithString:[NSString stringWithFormat:@"http://maciasl.sourceforge.net/10.%d/iasl%ld", osmajor, iasl.unsignedIntegerValue]] toURL:[NSBundle.mainBundle URLForAuxiliaryExecutable:[NSString stringWithFormat:@"iasl%ld", iasl.unsignedIntegerValue]] perform:^(bool success){
            muteWithNotice(self->_update, fractionCompleted,);
            if (success && [NSUserDefaults.standardUserDefaults integerForKey:@"acpi"] == iasl.unsignedIntegerValue)
                [iASL observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
            dispatch_group_leave(g);
        }];
        [_update resignCurrent];
    }
    dispatch_group_notify(g, dispatch_get_main_queue(), ^{
        muteWithNotice(self, update, self->_update = nil);
        [sender setEnabled:true];
    });
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
-(NSString *)compiler {
    return iASL.compiler;
}

-(NSArray *)deviceProperties {
    return iASL.deviceProperties;
}

-(NSArray *)log {
    return [_log copy];
}

-(NSArray *)logAtIndexes:(NSIndexSet *)indexes {
    return [_log objectsAtIndexes:indexes];
}

-(id)objectInLogAtIndex:(NSUInteger)index {
    return [_log objectAtIndex:index];
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
    id delegate = self.delegate;
    if (!NSEqualRanges(range, self.selectedRange)
        && NSTextFinder._globalTextFinder.client == (id)self
        && delegate && [delegate conformsToProtocol:@protocol(NSTextFinderIndication)])
        [(id<NSTextFinderIndication>)delegate textViewDidShowFindIndicator:[NSNotification notificationWithName:@"NSTextViewDidShowFindIndicatorNotification" object:self userInfo:@{@"NSFindIndicatorRange":[NSValue valueWithRange:range]}]];
}

@end

@implementation FSRulerView
static NSDictionary *style;

+(void)load {
    NSMutableParagraphStyle *temp = [NSMutableParagraphStyle new];
    temp.alignment = NSRightTextAlignment;
    NSFont *font = nil;
    if ([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)])
        font = [NSFont monospacedDigitSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightRegular];
    else
        font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    style = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:[temp copy]};
}

-(instancetype)init {
    self = [super init];
    if (self)
        super.reservedThicknessForMarkers = 0;
    return self;
}

-(void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    NSScrollView *scrollView = self.scrollView;
    if (!scrollView) return;
    NSInteger height = (NSInteger)[[(NSTextView *)scrollView.documentView layoutManager] defaultLineHeightForFont:NSFontManager.sharedFontManager.selectedFont], start = (NSInteger)floor((scrollView.documentVisibleRect.origin.y + rect.origin.y) / height) + 1, stop = 1 + start + (NSInteger)ceil(rect.size.height / height);
    if (self.ruleThickness < MAX(16,((NSInteger)log10(stop)+1)*8)) {
        self.ruleThickness = ((NSInteger)log10(stop)+1)*8;
        return;
    }
    rect.size.width -= 2;
    rect.origin.y -= (NSInteger)(scrollView.documentVisibleRect.origin.y+rect.origin.y) % height - (height-(NSFont.smallSystemFontSize+2))/2 + 1;
    rect.size.height = height;
    while (start < stop) {
        [[NSString stringWithFormat:@"%ld", start++] drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:style];
        rect.origin.y += height;
    }
}

@end
