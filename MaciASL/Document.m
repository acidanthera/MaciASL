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
#import "Patch.h"
#import "AppDelegate.h"

@implementation Document {
    @private
    DefinitionBlock *_oldNav;
    Patcher *_patch;
    __unsafe_unretained IBOutlet NSTextView *_textView;
    __unsafe_unretained IBOutlet NSOutlineView *_navView;
    __unsafe_unretained IBOutlet NSTreeController *_navController;
    __unsafe_unretained IBOutlet NSSearchField *_filter;
    __unsafe_unretained IBOutlet NSWindow *_jump;
    NSTextStorage *_text;
    NSString *_tableName;
    NSURL *_tableset;
    Colorize *_colorize;
}

#pragma mark NSDocument
- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        _jumpLine = 1;
        _nav = [DefinitionBlock emptyBlock];
        _text = [NSTextStorage new];
        _text.delegate = self;
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
    [_navView registerForDraggedTypes:@[kUTTypeNavObject]];
    _textView.enclosingScrollView.hasVerticalRuler = true;
    _textView.enclosingScrollView.verticalRulerView = [FSRulerView new];
    _textView.enclosingScrollView.rulersVisible = true;
    [_textView.layoutManager replaceTextStorage:_text];
    _textView.enabledTextCheckingTypes = 0;
    SplitView([[aController.window.contentView subviews] firstObject]);
    NSTextContainer *cont = _textView.textContainer;
    cont.containerSize = NSMakeSize(1e7, 1e7);
    cont.widthTracksTextView = false;
    cont.heightTracksTextView = false;
    _colorize = [[Colorize alloc] initWithTextView:_textView];
    [(AppDelegate *)[(NSApplication *)NSApp delegate] changeFont:nil];
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
    NSURL *url = self.fileURL;
    if (!url)
        return false;
    id value;
    if (![url getResourceValue:&value forKey:NSURLIsWritableKey error:&err] || ![value boolValue])
        return true;
    if (![url getResourceValue:&value forKey:NSURLIsUserImmutableKey error:&err] || [value boolValue])
        return true;
    return false;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError * __autoreleasing *)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSData *data;
    if ([typeName isEqualToString:kUTTypeDSL])
        data = [_text.string dataUsingEncoding:NSASCIIStringEncoding];
    else if ([typeName isEqualToString:kUTTypeAML]) {
        if (self.isLocked)
            return [NSData dataWithContentsOfURL:self.fileURL];
        [self quickCompile:(self.isDraft && self.autosavingIsImplicitlyCancellable) hold:true];
        if (!_result.error) {
            data = [NSData dataWithContentsOfURL:_result.url];
            NSError *err;
            if (![NSFileManager.defaultManager removeItemAtURL:_result.url error:&err])
                ModalError(err);
        }
        else if (outError != NULL) {
            [(AppDelegate *)[(NSApplication *)NSApp delegate] showSummary:self];
            *outError = [NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:@{NSLocalizedDescriptionKey:@"Compilation Failed", NSLocalizedFailureReasonErrorKey:@"\nThe compiler returned one or more errors."}];
        }
    }
    return data;
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError * __autoreleasing *)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if ([typeName isEqualToString:kUTTypeDSL])
        _text.mutableString.string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    else if ([typeName isEqualToString:kUTTypeAML]) {
        iASLDecompilationResult *decompile = [iASL decompileAML:data name:_tableName tableset:_tableset];
        if (!decompile.error)
            _text.mutableString.string = decompile.string;
        else if (outError != NULL)
            *outError = decompile.error;
    }
    else if (outError != NULL)
        *outError = [NSError errorWithDomain:kMaciASLDomain code:kFileError userInfo:@{NSLocalizedDescriptionKey:@"Filetype Error", NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Unknown Filetype %@", typeName]}];
    if (_text.length) return true;
    return false;
}

-(BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    if (url)
        return [super revertToContentsOfURL:url ofType:typeName error:outError];
    else if ([_tableset isEqual:kSystemTableset])
        return [self readFromData:[iASL fetchTable:_tableName] ofType:kUTTypeAML error:outError];
    else if (_tableset)
        return [self readFromData:[(NSDictionary *)[(NSDictionary *)[NSDictionary dictionaryWithContentsOfURL:_tableset] objectForKey:@"Tables"] objectForKey:_tableName] ofType:kUTTypeAML error:outError];
    return true;
}

-(instancetype)initWithType:(NSString *)typeName tableName:(NSString *)tableName tableset:(NSURL *)tableset text:(NSString *)text error:(NSError *__autoreleasing *)outError {
    self = [super initWithType:typeName error:outError];
    if (self) {
        _tableName = tableName;
        _tableset = tableset;
        _text.mutableString.string = text;
    }
    return self;
}

+(BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
    return true;
}

-(NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError {
    NSTextView *print = [[NSTextView alloc] initWithFrame:self.printInfo.imageablePageBounds];
    print.string = _text.string;
    return [NSPrintOperation printOperationWithView:print];
}

-(void)close {
    _navView = nil;
    _colorize = nil;
    [super close];
}

#pragma mark Readonly Properties
-(Patcher *)patch {
    return _patch ?: (_patch = [[Patcher alloc] initWithTextView:_textView]);
}

#pragma mark Actions
-(void)quickCompile:(bool)force hold:(bool)hold {
    assignWithNotice(self, result, [iASL compileDSL:_text.string name:_tableName tableset:_tableset force:force]);
    if (!hold)
        [NSFileManager.defaultManager removeItemAtURL:_result.url error:nil];
}

-(void)quickPatch:(NSString *)string {
    if (self.isLocked) return;
    PatchFile *p = [[PatchFile alloc] initWithPatch:string];
    [p patchTextView:_textView apply:true];
}

-(id)asPatch:(NSScriptCommand *)command {
    if (self.isLocked) {
        command.scriptErrorNumber = kLockError;
        command.scriptErrorString = @"Document is locked";
        return nil;
    }
    NSString *path = [[command.arguments objectForKey:@"patchfile"] path];
    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        [self quickPatch:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL]];
        return self.patch.patchFile.results;
    } else {
        command.scriptErrorNumber = kAScriptFileError;
        command.scriptErrorString = @"File not found";
        command.scriptErrorOffendingObjectDescriptor = [NSAppleEventDescriptor descriptorWithString:path];
        return nil;
    }
}

-(id)asCompile:(NSScriptCommand *)command {
    [self quickCompile:false hold:false];
    NSMutableArray *temp = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    for (Notice *notice in _result.notices)
        [[temp objectAtIndex:notice.type] addObject:[NSString stringWithFormat:@"%ld: %@", notice.line, notice.message]];
    return @{@"errors":[[temp objectAtIndex:3] copy], @"warnings":[temp.firstObject copy], @"remarks":[[temp objectAtIndex:4] copy], @"optimizations":[[temp objectAtIndex:5] copy]};
}

#pragma mark GUI
-(IBAction)filterTree:(id)sender {
    if (![[sender stringValue] length]) {
        assignWithNotice(self, nav, _oldNav);
        _oldNav = nil;
    }
    else {
        if (!_oldNav)
            _oldNav = _nav;
        assignWithNotice(self, nav, [_oldNav filteredWithString:[sender stringValue]])
    }
    [_navView expandItem:[_navView itemAtRow:0]];
    [self textViewDidChangeSelection:nil];
}

-(IBAction)patch:(id)sender {
    [self.patch show:nil];
}

-(IBAction)compile:(id)sender {
    [self quickCompile:false hold:false];
    NSError *e = _result.error;
    if (e.localizedFailureReason)
        [[NSAlert alertWithError:[NSError errorWithDomain:e.domain code:e.code userInfo:@{NSLocalizedDescriptionKey:e.localizedDescription,NSLocalizedRecoverySuggestionErrorKey:e.localizedFailureReason}]] beginSheetModalForWindow:self.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    else
        [(AppDelegate *)[(NSApplication *)NSApp delegate] showSummary:sender];
}

-(IBAction)hexConvert:(id)sender {
    NSString *number = [_text.string substringWithRange:_textView.selectedRange];
    if (!number.length) return;
    errno = 0;
    UInt64 internal = strtoll(number.UTF8String, nil, 0);
    if (errno) NSBeep();
    else [_textView insertText:[NSString stringWithFormat:[number hasPrefix:@"0x"]?@"%lld":@"0x%llX",internal] replacementRange:_textView.selectedRange];
}

-(IBAction)comment:(id)sender {
    NSUInteger start, end;
    [_text.string getLineStart:&start end:&end contentsEnd:NULL forRange:_textView.selectedRange];
    NSRange range = NSMakeRange(start - 1, 0), selection = _textView.selectedRange;
    while (NSMaxRange(range) < end) {
        range = [_text.string lineRangeForRange:NSMakeRange(NSMaxRange(range) + 1, 0)];
        bool comment = [_text.string characterAtIndex:range.location] == '/'
        && [_text.string characterAtIndex:range.location + 1] == '/';
        [_textView insertText:comment? @"" : @"//" replacementRange:NSMakeRange(range.location, comment * 2)];
        NSInteger offset = 2 - comment * 4;
        if (range.location < selection.location)
            selection.location += offset;
        else
            selection.length += offset;
        range.length += offset;
        end += offset;
    }
    _textView.selectedRange = selection;
}

-(IBAction)jumpToLine:(id)sender {
    [NSApp beginSheet:_jump modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)landOnLine:(id)sender {
    [NSApp endSheet:_jump];
    [_jump orderOut:sender];
    if ([[sender title] isEqualToString:@"Cancel"]) return;
    NSRange range = [self rangeForLine:_jumpLine];
    [_textView scrollRangeToVisible:range];
    [_textView showFindIndicatorForRange:range];
}

#pragma mark Functions
-(NSRange)rangeForLine:(NSUInteger)ln {
    __block NSUInteger i = 0;
    __block NSUInteger offset = 0;
    [_text.string enumerateLinesUsingBlock:^void(NSString *line, BOOL *stop){
        if (++i == ln) *stop = true;
        else offset += line.length+1;
    }];
    return [_text.string lineRangeForRange:NSMakeRange(offset, 0)];
}

-(NSInteger)navRowForRange:(NSRange)range {
    NSTreeNode *obj = [_navView itemAtRow:0];
    NSUInteger i = 0;
    NSUInteger length = obj.childNodes.count;
    while (length) {
        while (i < length) {
            if (NSLocationInRange(range.location, [(NavObject *)[(NSTreeNode *)[obj.childNodes objectAtIndex:i] representedObject] range])) {
                obj = [obj.childNodes objectAtIndex:i];
                [_navView expandItem:obj];
                length = [obj.childNodes count];
                i = 0;
                break;
            }
            i++;
        }
        if (i) break;
    }
    return [_navView rowForItem:obj];
}

-(void)buildNav {
    if (!_navView) return;
    if (_filter.stringValue.length) {
        _oldNav = [DefinitionBlock build:_text.string];
        [self filterTree:_filter];
        return;
    }
    assignWithNotice(self, nav, [DefinitionBlock build:_text.string]);
    if (!_navView) return;
    [_navView expandItem:[_navView itemAtRow:0]];
    [self textViewDidChangeSelection:nil];
}

#pragma mark NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([notification.object selectedRow] == -1) return;
    Notice *notice = [_result.notices objectAtIndex:[notification.object selectedRow]];
    NSRange range = [self rangeForLine:notice.line];
    [_textView scrollRangeToVisible:range];
    [_textView showFindIndicatorForRange:range];
}

#pragma mark NSOutlineViewDelegate
-(void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if (_navView != _navView.window.firstResponder) return;
    NSRange range = NSMakeRange([[(NSTreeNode *)[_navView itemAtRow:_navView.selectedRow] representedObject] range].location, 0);
    if (NSMaxRange(range) == 0) return;
    [_textView scrollRangeToVisible:range];
    [_textView showFindIndicatorForRange:[_text.string lineRangeForRange:range]];
}

#pragma mark NSOutlineViewDataSource
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:items.count];
    for (NSTreeNode *item in items) {
        NSUInteger path[item.indexPath.length];
        [item.indexPath getIndexes:(NSUInteger *)&path];
        [objects addObject:[NSPasteboardItem new]];
        [objects.lastObject setData:[NSData dataWithBytes:path length:sizeof(path)] forType:kUTTypeNavObject];
        [objects.lastObject setString:[_text.string substringWithRange:[[item representedObject] range]] forType:NSPasteboardTypeString];
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
            NSTreeNode *node = [_navController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndexes:(NSUInteger *)data.bytes length:data.length/sizeof(NSUInteger)]];
            [_textView insertText:@"" replacementRange:[[node representedObject] range]];
            [outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:[node.parentNode.childNodes indexOfObjectIdenticalTo:node]] inParent:node.parentNode withAnimation:NSTableViewAnimationEffectFade|NSTableViewAnimationSlideUp];
        }
    }
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (!item) return NSDragOperationNone;
    if ([[(NSTreeNode *)item representedObject] isMemberOfClass:DefinitionBlock.class] && index == NSOutlineViewDropOnItemIndex) return NSDragOperationNone;
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
        if (index) range = [[item childNodes] count]?[[(NSTreeNode *)[[(NSTreeNode *)item childNodes] objectAtIndex:index-1] representedObject] range]:[[(NSTreeNode *)item representedObject] range];
        else range = NSMakeRange([[(NSTreeNode *)item representedObject] contentRange:_text.string].location, 0);
        range = NSMakeRange(NSMaxRange(range), 0);
    }
    else {
        range = [[(NSTreeNode *)item representedObject] range];
        index = [[[item parentNode] childNodes] indexOfObjectIdenticalTo:item];
        item = [item parentNode];
        [outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:item withAnimation:NSTableViewAnimationEffectFade|NSTableViewAnimationSlideUp];
    }
    for (NSPasteboardItem *paste in [info.draggingPasteboard.pasteboardItems copy]) {
        [_textView.undoManager beginUndoGrouping];
        [_textView insertText:[paste stringForType:NSPasteboardTypeString] replacementRange:range];
        if (move && info.draggingSource == outlineView) {
            NSData *data = [paste dataForType:kUTTypeNavObject];
            NSTreeNode *node = [_navController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndexes:(NSUInteger *)data.bytes length:data.length/sizeof(NSUInteger)]];
            NSRange oldRange = [[node representedObject] range];
            if (NSMaxRange(range) < oldRange.location) oldRange.location+=oldRange.length-range.length;
            [_textView insertText:@"" replacementRange:oldRange];
            NSInteger oldIndex = [node.parentNode.childNodes indexOfObjectIdenticalTo:node];
            [outlineView moveItemAtIndex:oldIndex-(item == node.parentNode && oldIndex > index && !insert) inParent:node.parentNode toIndex:index-(item == node.parentNode && oldIndex < index) inParent:item];
        }
        [_textView.undoManager endUndoGrouping];
        _textView.selectedRange = NSMakeRange(range.location, 0);
    }
    if (move && info.draggingSource == outlineView) [info.draggingPasteboard clearContents];
    [Document cancelPreviousPerformRequestsWithTarget:self selector:@selector(buildNav) object:nil];
    [self buildNav];
    return true;
}

#pragma mark NSTextStorageDelegate
-(void)textStorageDidProcessEditing:(NSNotification *)notification {
    [_colorize textStorageDidProcessEditing:notification];
    [Document cancelPreviousPerformRequestsWithTarget:self selector:@selector(buildNav) object:nil];
    [self performSelector:@selector(buildNav) withObject:nil afterDelay:1.5];
}

#pragma mark NSTextViewDelegate
-(BOOL)textView:(NSTextView *)view doCommandBySelector:(SEL)commandSelector{
    if (commandSelector == @selector(insertNewline:)) {
        NSRange range = view.selectedRange;
        [_textView insertText:[@"\n" stringByAppendingString:[Patcher entab:lineForRange(_text.string, NSMakeRange(NSMaxRange(range)+(range.location!=_text.string.length), 0)) with:lineForRange(_text.string, range)]]];
        return true;
    }
    else if (commandSelector == @selector(insertTab:)) {
        [_textView insertText:@"    "];
        return true;
    }
    return false;
}

-(void)textViewDidChangeSelection:(NSNotification *)notification {
    NSRange sel = _textView.selectedRange;
    if (!sel.location || sel.location == _text.string.length) return;
    NSInteger i = [self navRowForRange:sel];
    [_navView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:false];
    [_navView scrollRowToVisible:i];
}

-(void)textViewDidShowFindIndicator:(NSNotification *)notification {
    [_navView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self navRowForRange:[[notification.userInfo objectForKey:@"NSFindIndicatorRange"] rangeValue]]] byExtendingSelection:false];
    [_navView scrollRowToVisible:_navView.selectedRow];
}

@end
