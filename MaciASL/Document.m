//
//  Document.m
//  MaciASL
//
//  Created by PHPdev32 on 9/21/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Document.h"
#import "iASL.h"
#import "Navigator.h"
#import "Colorize.h"
#import "AppDelegate.h"

@implementation Document

@synthesize textView;
@synthesize navView;
@synthesize navController;
@synthesize jump;
@synthesize jumpLine;
@synthesize nav;
@synthesize filter;
@synthesize text;
@synthesize summary;
@synthesize colorize;

#pragma mark NSDocument
- (id)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        jumpLine = 1;
        nav = [DefinitionBlock create:@"Unknown" withRange:NSMakeRange(0, 0)];
        text = [NSTextStorage new];
        text.delegate = self;
    }
    return self;
}
- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}
- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    [navView registerForDraggedTypes:@[kUTTypeNavObject]];
    textView.enclosingScrollView.hasVerticalRuler = true;
    textView.enclosingScrollView.verticalRulerView = [FSRulerView new];
    textView.enclosingScrollView.rulersVisible = true;
    [textView.layoutManager replaceTextStorage:text];
    textView.enabledTextCheckingTypes = 0;
    SplitView([[aController.window.contentView subviews] objectAtIndex:0]);
    NSTextContainer *cont = textView.textContainer;
    cont.containerSize = NSMakeSize(1e7, 1e7);
    cont.widthTracksTextView = false;
    cont.heightTracksTextView = false;
    colorize = [Colorize create:textView];
    [(AppDelegate *)[NSApp delegate] changeFont:nil];
}
+ (BOOL)autosavesInPlace {
    return true;
}
- (BOOL)isDraft {
    if ([self.superclass instancesRespondToSelector:_cmd])
        return [self.superclass instanceMethodForSelector:_cmd](self,_cmd) != nil;
    return !self.fileURL;
}
- (BOOL)isLocked {
    if ([self.superclass instancesRespondToSelector:_cmd])
        return [self.superclass instanceMethodForSelector:_cmd](self,_cmd) != nil;
    NSError *err;
    if (![self checkAutosavingSafetyAndReturnError:&err])
        return true;
    if (!self.fileURL)
        return false;
    if (![NSFileManager.defaultManager isWritableFileAtPath:self.fileURL.path])
        return true;
    if ([[[NSFileManager.defaultManager attributesOfItemAtPath:self.fileURL.path error:&err] objectForKey:NSFileImmutable] boolValue])
        return true;
    return false;
}
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSData *data;
    if ([typeName isEqualToString:kUTTypeDSL])
        data = [text.string dataUsingEncoding:NSASCIIStringEncoding];
    else if ([typeName isEqualToString:kUTTypeAML]) {
        if (self.isLocked)
            return [NSFileManager.defaultManager contentsAtPath:self.fileURL.path];
        [self quickCompile:(self.isDraft && self.autosavingIsImplicitlyCancellable) hold:true];
        if ([[summary objectForKey:@"success"] boolValue]) {
            data = [NSFileManager.defaultManager contentsAtPath:[summary objectForKey:@"aml"]];
            NSError *err;
            if (![NSFileManager.defaultManager removeItemAtPath:[summary objectForKey:@"aml"] error:&err])
                ModalError(err);
        }
        else if (outError != NULL) {
            [(AppDelegate *)[NSApp delegate] showSummary:self];
            *outError = [NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:@{NSLocalizedDescriptionKey:@"Compilation Failed", NSLocalizedFailureReasonErrorKey:@"\nThe compiler returned one or more errors."}];
        }
    }
    return data;
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if ([typeName isEqualToString:kUTTypeDSL])
        text.mutableString.string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    else if ([typeName isEqualToString:kUTTypeAML]) {
        NSDictionary *decompile = [iASL decompile:data withResolution:nil];
        if ([[decompile objectForKey:@"status"] boolValue])
            text.mutableString.string = [decompile objectForKey:@"object"];
        else if (outError != NULL)
            *outError = [decompile objectForKey:@"object"];
    }
    else if (outError != NULL)
        *outError = [NSError errorWithDomain:kMaciASLDomain code:kFileError userInfo:@{NSLocalizedDescriptionKey:@"Filetype Error", NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Unknown Filetype %@", typeName]}];
    if (text.length) return true;
    return false;
}
+(BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName{
    return true;
}
-(NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError{
    NSTextView *print = [[NSTextView alloc] initWithFrame:self.printInfo.imageablePageBounds];
    print.string = text.string;
    return [NSPrintOperation printOperationWithView:print];
}
-(void)close{
    navView = nil;
    colorize = nil;
    [super close];
}
-(Patcher *)patch{
    if (!_patch) _patch = [Patcher create:self];
    return _patch;
}
#pragma mark Actions
-(void)quickCompile:(bool)force hold:(bool)hold{
    self.summary = [iASL compile:text.string force:force];
    if (hold || ![[summary objectForKey:@"success"] boolValue]) return;
    [NSFileManager.defaultManager removeItemAtPath:[summary objectForKey:@"aml"] error:nil];
}
-(void)quickPatch:(NSString *)string{
    if (self.isLocked) return;
    self.patch.patch = string;
    [Document cancelPreviousPerformRequestsWithTarget:self.patch selector:@selector(preview) object:nil];
    [self.patch preview];
    [self.patch apply:self];
}
-(id)asPatch:(NSScriptCommand *)command{
    if (self.isLocked) {
        command.scriptErrorNumber = kLockError;
        command.scriptErrorString = @"Document is locked";
        return nil;
    }
    NSString *path = [[command.arguments objectForKey:@"patchfile"] path];
    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        [self quickPatch:[[NSString alloc] initWithData:[NSFileManager.defaultManager contentsAtPath:path] encoding:NSUTF8StringEncoding]];
        return @{@"patches":[NSNumber numberWithLong:self.patch.patchFile.patches.count], @"changes":[NSNumber numberWithLong:self.patch.patchFile.preview.count-self.patch.patchFile.rejects], @"rejects":[NSNumber numberWithLong:self.patch.patchFile.rejects]};
    } else {
        command.scriptErrorNumber = kAScriptFileError;
        command.scriptErrorString = @"File not found";
        command.scriptErrorOffendingObjectDescriptor = [NSAppleEventDescriptor descriptorWithString:path];
        return nil;
    }
}
-(id)asCompile:(NSScriptCommand *)command{
    [self quickCompile:false hold:false];
    NSMutableArray *temp = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    for (Notice *notice in [summary objectForKey:@"notices"])
        [[temp objectAtIndex:notice.type] addObject:[NSString stringWithFormat:@"%ld: %@", notice.line, notice.message]];
    return @{@"errors":[[temp objectAtIndex:3] copy], @"warnings":[[temp objectAtIndex:0] copy], @"remarks":[[temp objectAtIndex:4] copy], @"optimizations":[[temp objectAtIndex:5] copy]};
}

#pragma mark GUI
-(IBAction)filterTree:(id)sender{//TODO: keep parents, or use oldNav for breadcrumb?
    if (![[sender stringValue] length]) {
        self.nav = _oldNav;
        _oldNav = nil;
    }
    else {
        if (!_oldNav) _oldNav = nav;
        nav = [DefinitionBlock create:_oldNav.name withRange:_oldNav.range];
        NSMutableArray *temp = [_oldNav flat];
        [temp filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings){
            return [[evaluatedObject name] rangeOfString:[sender stringValue] options:NSCaseInsensitiveSearch].location != NSNotFound;
        }]];
        if (temp.count && [temp objectAtIndex:0] == _oldNav) [temp removeObjectAtIndex:0];
        muteWithNotice(self, nav, [nav setChildren:temp])
    }
    [navView expandItem:[navView itemAtRow:0]];
    [self textViewDidChangeSelection:nil];
}
-(IBAction)patch:(id)sender{
    [self.patch beginSheet];
}
-(IBAction)compile:(id)sender{
    [self quickCompile:false hold:false];
    [(AppDelegate *)[NSApp delegate] showSummary:sender];
}
-(IBAction)hexConvert:(id)sender{
    NSString *number = [text.string substringWithRange:textView.selectedRange];
    if (!number.length) return;
    errno = 0;
    UInt64 internal = strtoll(number.UTF8String, nil, 0);
    if (errno) NSBeep();
    else [textView insertText:[NSString stringWithFormat:[number hasPrefix:@"0x"]?@"%lld":@"0x%llX",internal] replacementRange:textView.selectedRange];
}
-(IBAction)comment:(id)sender {
    NSUInteger start, end;
    [text.string getLineStart:&start end:&end contentsEnd:NULL forRange:textView.selectedRange];
    NSRange range = NSMakeRange(start - 1, 0), selection = textView.selectedRange;
    while (NSMaxRange(range) < end) {
        range = [text.string lineRangeForRange:NSMakeRange(NSMaxRange(range) + 1, 0)];
        bool comment = [text.string characterAtIndex:range.location] == '/'
        && [text.string characterAtIndex:range.location + 1] == '/';
        [textView insertText:comment? @"" : @"//" replacementRange:NSMakeRange(range.location, comment * 2)];
        NSInteger offset = 2 - comment * 4;
        if (range.location < selection.location)
            selection.location += offset;
        else
            selection.length += offset;
        range.length += offset;
        end += offset;
    }
    textView.selectedRange = selection;
}
-(IBAction)jumpToLine:(id)sender{
    [NSApp beginSheet:jump modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
-(IBAction)landOnLine:(id)sender{
    [NSApp endSheet:jump];
    [jump orderOut:sender];
    if ([[sender title] isEqualToString:@"Cancel"]) return;
    NSRange range = [self rangeForLine:jumpLine];
    [textView scrollRangeToVisible:range];
    [textView showFindIndicatorForRange:range];
}
#pragma mark Functions
-(NSRange)rangeForLine:(NSUInteger)ln{
    __block NSUInteger i = 0;
    __block NSUInteger offset = 0;
    [text.string enumerateLinesUsingBlock:^void(NSString *line, BOOL *stop){
        if (++i == ln) *stop = true;
        else offset += line.length+1;
    }];
    return [text.string lineRangeForRange:NSMakeRange(offset, 0)];
}
-(NSInteger)navRowForRange:(NSRange)range{
    NSTreeNode *obj = [navView itemAtRow:0];
    NSUInteger i = 0;
    NSUInteger length = obj.childNodes.count;
    while (length) {
        while (i < length) {
            if (NSLocationInRange(range.location, [(NavObject *)[[obj.childNodes objectAtIndex:i] representedObject] range])) {
                obj = [obj.childNodes objectAtIndex:i];
                [navView expandItem:obj];
                length = [obj.childNodes count];
                i = 0;
                break;
            }
            i++;
        }
        if (i) break;
    }
    return [navView rowForItem:obj];
}
-(void)buildNav{
    if (!navView) return;
    if (filter.stringValue.length) {
        _oldNav = [DefinitionBlock build:text.string];
        [self filterTree:filter];
        return;
    }
    self.nav = [DefinitionBlock build:text.string];
    if (!navView) return;
    [navView expandItem:[navView itemAtRow:0]];
    [self textViewDidChangeSelection:nil];
}
#pragma mark NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification{//TODO: autofixes or suggestions
    if ([notification.object selectedRow] == -1) return;
    Notice *notice = [[summary objectForKey:@"notices"] objectAtIndex:[notification.object selectedRow]];
    NSRange range = [self rangeForLine:notice.line];
    [textView scrollRangeToVisible:range];
    [textView showFindIndicatorForRange:range];
}
#pragma mark NSOutlineViewDelegate
-(void)outlineViewSelectionDidChange:(NSNotification *)notification{//TODO: better integration, use Tab/Return/Esc hotkeys?
    if (navView != navView.window.firstResponder) return;
    NSRange range = NSMakeRange([[[navView itemAtRow:navView.selectedRow] representedObject] range].location, 0);
    if (NSMaxRange(range) == 0) return;
    [textView scrollRangeToVisible:range];
    [textView showFindIndicatorForRange:[text.string lineRangeForRange:range]];
}
#pragma mark NSOutlineViewDataSource
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:items.count];
    for (NSTreeNode *item in items) {
        NSUInteger path[item.indexPath.length];
        [item.indexPath getIndexes:(NSUInteger *)&path];
        [objects addObject:[NSPasteboardItem new]];
        [objects.lastObject setData:[NSData dataWithBytes:path length:sizeof(path)] forType:kUTTypeNavObject];
        [objects.lastObject setString:[text.string substringWithRange:[[item representedObject] range]] forType:NSPasteboardTypeString];
    }
    [pasteboard writeObjects:objects];
    return true;
}
-(void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if (operation == NSDragOperationDelete)
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, screenPoint, NSZeroSize, nil, nil, nil);
    if (operation & (NSDragOperationDelete|NSDragOperationMove)) {
        for (NSPasteboardItem *paste in session.draggingPasteboard.pasteboardItems) {
            NSData *data = [paste dataForType:kUTTypeNavObject];
            NSTreeNode *node = [navController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndexes:(NSUInteger *)data.bytes length:data.length/sizeof(NSUInteger)]];
            [textView insertText:@"" replacementRange:[[node representedObject] range]];
            [outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:[node.parentNode.childNodes indexOfObjectIdenticalTo:node]] inParent:node.parentNode withAnimation:NSTableViewAnimationEffectFade|NSTableViewAnimationSlideUp];//TODO: allow Generic?
        }
    }
}
-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {//TODO: disallow replacing parent?
    if (!item) return NSDragOperationNone;
    if ([[item representedObject] isMemberOfClass:DefinitionBlock.class] && index == NSOutlineViewDropOnItemIndex) return NSDragOperationNone;
    if (NSEvent.modifierFlags&NSControlKeyMask) {
        [outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
        if (NSCursor.currentCursor != NSCursor.disappearingItemCursor) [NSCursor.disappearingItemCursor push];
        return NSDragOperationDelete;
    }
    else {
        [NSCursor.disappearingItemCursor pop];
        return  NSEvent.modifierFlags&NSAlternateKeyMask?NSDragOperationCopy:NSDragOperationMove;
    }
}
-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    if (NSEvent.modifierFlags&NSControlKeyMask) return true;
    bool move = ~NSEvent.modifierFlags&NSAlternateKeyMask, insert = index != NSOutlineViewDropOnItemIndex;
    NSRange range;
    if (insert) {
        if (index) range = [[item childNodes] count]?[[[[item childNodes] objectAtIndex:index-1] representedObject] range]:[[item representedObject] range];
        else range = NSMakeRange([[item representedObject] contentRange:text.string].location, 0);
        range = NSMakeRange(NSMaxRange(range), 0);//FIXME: better insertion range
    }
    else {
        range = [[item representedObject] range];
        index = [[[item parentNode] childNodes] indexOfObjectIdenticalTo:item];
        item = [item parentNode];
        [outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:item withAnimation:NSTableViewAnimationEffectFade|NSTableViewAnimationSlideUp];
    }
    for (NSPasteboardItem *paste in [info.draggingPasteboard.pasteboardItems copy]) {
        [textView.undoManager beginUndoGrouping];
        [textView insertText:[paste stringForType:NSPasteboardTypeString] replacementRange:range];
        if (move && info.draggingSource == outlineView) {
            NSData *data = [paste dataForType:kUTTypeNavObject];
            NSTreeNode *node = [navController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndexes:(NSUInteger *)data.bytes length:data.length/sizeof(NSUInteger)]];
            NSRange oldRange = [[node representedObject] range];
            if (NSMaxRange(range) < oldRange.location) oldRange.location+=oldRange.length-range.length;
            [textView insertText:@"" replacementRange:oldRange];
            NSInteger oldIndex = [node.parentNode.childNodes indexOfObjectIdenticalTo:node];
            [outlineView moveItemAtIndex:oldIndex-(item == node.parentNode && oldIndex > index && !insert) inParent:node.parentNode toIndex:index-(item == node.parentNode && oldIndex < index) inParent:item];
        }
        [textView.undoManager endUndoGrouping];
        textView.selectedRange = NSMakeRange(range.location, 0);
    }
    if (move && info.draggingSource == outlineView) [info.draggingPasteboard clearContents];
    [Document cancelPreviousPerformRequestsWithTarget:self selector:@selector(buildNav) object:nil];
    [self buildNav];
    return true;
}
#pragma mark NSTextStorageDelegate
-(void)textStorageDidProcessEditing:(NSNotification *)notification{
    [colorize textStorageDidProcessEditing:notification];
    [Document cancelPreviousPerformRequestsWithTarget:self selector:@selector(buildNav) object:nil];
    [self performSelector:@selector(buildNav) withObject:nil afterDelay:1.5];
}
#pragma mark NSTextViewDelegate
-(BOOL)textView:(NSTextView *)view doCommandBySelector:(SEL)commandSelector{//TODO: Re-indent selection?
    if (commandSelector == @selector(insertNewline:)) {
        NSRange range = view.selectedRange;
        [textView insertText:[@"\n" stringByAppendingString:[Patcher entab:lineForRange(text.string, NSMakeRange(NSMaxRange(range)+(range.location!=text.string.length), 0)) with:lineForRange(text.string, range)]]];
        return true;
    }
    else if (commandSelector == @selector(insertTab:)) {
        [textView insertText:@"    "];
        return true;
    }
    return false;
}
-(void)textViewDidChangeSelection:(NSNotification *)notification{
    NSRange sel = textView.selectedRange;
    if (!sel.location || sel.location == text.string.length) return;
    NSInteger i = [self navRowForRange:sel];
    [navView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:false];
    [navView scrollRowToVisible:i];
}
-(void)textViewDidShowFindIndicator:(NSNotification *)notification{
    [navView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self navRowForRange:[[notification.userInfo objectForKey:@"NSFindIndicatorRange"] rangeValue]]] byExtendingSelection:false];
    [navView scrollRowToVisible:navView.selectedRow];
}

@end
