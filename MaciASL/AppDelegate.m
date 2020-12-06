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
      @"style": @"Default",
      @"dsdt": @(YES),
      @"suggest": @(NO),
      @"iasl": @"stable",
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
      @"font": @{@"name": @"Menlo", @"size": @12},
      @"sources": @[
        @{@"name": @"ASRock", @"url": @"http://maciasl.sourceforge.net/pjalm/asrock"},
        @{@"name": @"ASUS", @"url": @"http://maciasl.sourceforge.net/pjalm/asus"},
        @{@"name": @"AsusSMC-Patches", @"url": @"https://raw.githubusercontent.com/hieplpvip/AsusSMC/master"},
        @{@"name": @"General", @"url": @"http://maciasl.sourceforge.net/pjalm/general"},
        @{@"name": @"Gigabyte", @"url": @"http://maciasl.sourceforge.net/pjalm/gigabyte"},
        @{@"name": @"Graphics", @"url": @"http://maciasl.sourceforge.net/pjalm/graphics"},
        @{@"name": @"Intel Series 6", @"url": @"http://maciasl.sourceforge.net/pjalm/intel6"},
        @{@"name": @"Intel Series 7", @"url": @"http://maciasl.sourceforge.net/pjalm/intel7"},
        @{@"name": @"Intel Series 8", @"url": @"http://maciasl.sourceforge.net/pjalm/intel8"},
        @{@"name": @"Intel Series 9", @"url": @"http://maciasl.sourceforge.net/pjalm/intel9"},
        @{@"name": @"MSI", @"url": @"http://maciasl.sourceforge.net/pjalm/msi"},
        @{@"name": @"Rehabman", @"url": @"http://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master"},
        @{@"name": @"Sourceforge", @"url": @"http://maciasl.sourceforge.net"},
        @{@"name": @"Toleda HDMI", @"url": @"http://raw.githubusercontent.com/toleda/audio_hdmi_uefi/master"},
        @{@"name": @"Toleda HDMI 8", @"url": @"http://raw.githubusercontent.com/toleda/audio_hdmi_8series/master"},
        @{@"name": @"Toleda ALC", @"url": @"http://raw.githubusercontent.com/toleda/audio_ALCInjection/master"},
        @{@"name": @"VoodooI2C-Patches", @"url": @"http://raw.githubusercontent.com/alexandred/VoodooI2C-Patches/master"},
        @{@"name": @"Zotac", @"url": @"http://maciasl.sourceforge.net/pjalm/zotac"},
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
#if defined(__i386__) || defined(__x86_64__)
    [DocumentController.sharedDocumentController newDocumentFromACPI:@"DSDT" saveFirst:false];
#endif
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
    dispatch_group_t g = dispatch_group_create();
    NSArray * versions = @[@"stable", @"dev", @"legacy"];
    muteWithNotice(self, update, _update = [NSProgress progressWithTotalUnitCount:versions.count]);

    for (NSString *iasl in versions) {
        [_update becomeCurrentWithPendingUnitCount:1];
        dispatch_group_enter(g);
        NSURL *src = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/acidanthera/MaciASL/raw/master/Dist/iasl-%@", iasl]];
        NSURL *dst = [[[NSBundle.mainBundle executableURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:[NSString stringWithFormat:@"iasl-%@", iasl]];
        [URLTask get:src toURL:dst perform:^(bool success){
            muteWithNotice(self->_update, fractionCompleted, self->_update.completedUnitCount++);
            if (success && [[NSUserDefaults.standardUserDefaults stringForKey:@"iasl"] isEqualToString:iasl])
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
    save.prompt = NSLocalizedString(@"export-tableset", @"Export Tableset");
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
    [NSNotificationCenter.defaultCenter postNotificationName:@"documentFontOrTextChanged" object:nil];
}

- (IBAction)generateSSDT:(id)sender {
    [[SSDTGen sharedGenerator] show:sender];
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

-(void)didChangeText {
    [NSNotificationCenter.defaultCenter postNotificationName:@"documentFontOrTextChanged" object:nil];
}

@end

@implementation FSRulerView
static NSDictionary *style;

+(void)load {
    NSMutableParagraphStyle *temp = [NSMutableParagraphStyle new];
    temp.alignment = NSRightTextAlignment;
    NSFont *font = nil;
    font = [NSFont fontWithName:@"Xcode Digits" size:NSFont.smallSystemFontSize];
    if (font == nil) {
#ifdef __MAC_10_11
        if ([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)])
            font = [NSFont monospacedDigitSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightLight];
        else
            font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightLight];
#else
        font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightLight];
#endif
    }
    style = @{NSFontAttributeName:font, NSForegroundColorAttributeName:NSColor.disabledControlTextColor, NSParagraphStyleAttributeName:[temp copy]};
}

-(instancetype)init {
    [FSRulerView load];
    self = [super init];
    if (self)
        super.reservedThicknessForMarkers = 0;
    [NSNotificationCenter.defaultCenter addObserverForName:@"documentFontOrTextChanged" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self setNeedsDisplay:YES];
    }];
    return self;
}

-(void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    NSScrollView *scrollView = self.scrollView;
    if (!scrollView) return;
    
    CGFloat lineHeight = [[(NSTextView *)scrollView.documentView layoutManager] defaultLineHeightForFont:NSFontManager.sharedFontManager.selectedFont];
    
    NSUInteger textLength = NSUIntegerMax;
    if ([scrollView.documentView isKindOfClass:NSTextView.class]) {
        NSTextView *textView = (NSTextView*)scrollView.documentView;
        textLength = [[textView.string componentsSeparatedByString:@"\n"] count];
    }

    // TODO: Calculate string width based on actual values instead of trying to estimate it.
    NSInteger height = (NSInteger)lineHeight, start = (NSInteger)((NSInteger)scrollView.documentVisibleRect.origin.y / lineHeight) + 1, stop = 1 + start + MIN((textLength - start), (NSInteger)ceil(scrollView.documentVisibleRect.size.height / height));
    if (self.ruleThickness < MAX(18,((NSInteger)log10(stop)+1)*9)) {
        self.ruleThickness = ((NSInteger)log10(stop)+1)*9;
        return;
    }
    
    rect.size.width -= 2;
    rect.origin.y -= (NSInteger)(scrollView.documentVisibleRect.origin.y) % height + 1;
    rect.size.height = height;
    while (start < stop) {
        if (start > 0) {
            NSAttributedString *str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", start++] attributes:style];
            [str drawInRect:rect];
        }
        else
            start++;
        rect.origin.y += height;
    }
}

@end
