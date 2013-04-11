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
        [text setDelegate:self];
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
    [textView.enclosingScrollView setHasVerticalRuler:true];
    [textView.enclosingScrollView setVerticalRulerView:[FSRulerView new]];
    [textView.enclosingScrollView setRulersVisible:true];
    [textView.layoutManager replaceTextStorage:text];
    [textView setEnabledTextCheckingTypes:0];
    SplitView([[aController.window.contentView subviews] objectAtIndex:0]);
    NSTextContainer *cont = textView.textContainer;
    [cont setContainerSize:NSMakeSize(1e7, 1e7)];
    [cont setWidthTracksTextView:false];
    [cont setHeightTracksTextView:false];
    colorize = [Colorize create:textView];
}
+ (BOOL)autosavesInPlace {
    return true;
}
#if MACOSX_DEPLOYMENT_TARGET <= MAC_OS_X_VERSION_10_7
- (BOOL)isDraft {
    return !self.fileURL;
}
- (BOOL)isLocked {
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
#endif
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSData *data;
    if ([typeName isEqualToString:kDSLfileType])
        data = [text.string dataUsingEncoding:NSASCIIStringEncoding];
    else if ([typeName isEqualToString:kAMLfileType]) {
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
            [[NSApp delegate] showSummary:self];
            *outError = [NSError errorWithDomain:kMaciASLDomain code:kCompilerError userInfo:@{NSLocalizedDescriptionKey:@"Compilation Failed", NSLocalizedFailureReasonErrorKey:@"\nThe compiler returned one or more errors."}];
        }
    }
    return data;
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if ([typeName isEqualToString:kDSLfileType])
        [self setDocument:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
    else if ([typeName isEqualToString:kAMLfileType]) {
        NSDictionary *decompile = [iASL decompile:data];
        if ([[decompile objectForKey:@"status"] boolValue])
            [self setDocument:[decompile objectForKey:@"object"]];
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
    [print setString:text.string];
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
//TODO: add object actions to navigator (delete, copy?)
#pragma mark Actions
-(void)quickCompile:(bool)force hold:(bool)hold{
    self.summary = [iASL compile:text.string force:force];
    if (hold || ![[summary objectForKey:@"success"] boolValue]) return;
    [NSFileManager.defaultManager removeItemAtPath:[summary objectForKey:@"aml"] error:nil];
}
-(void)quickPatch:(NSString *)string{
    if (self.isLocked) return;
    [self.patch setPatch:string];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.patch selector:@selector(preview) object:nil];
    [self.patch preview];
    [self.patch apply:self];
}
-(id)asPatch:(NSScriptCommand *)command{
    if (self.isLocked) {
        [command setScriptErrorNumber:kLockError];
        [command setScriptErrorString:@"Document is locked"];
        return nil;
    }
    NSString *path = [[command.arguments objectForKey:@"patchfile"] path];
    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        [self quickPatch:[[NSString alloc] initWithData:[NSFileManager.defaultManager contentsAtPath:path] encoding:NSUTF8StringEncoding]];
        return @{@"patches":[NSNumber numberWithLong:self.patch.patchFile.patches.count], @"changes":[NSNumber numberWithLong:self.patch.patchFile.preview.count-self.patch.patchFile.rejects], @"rejects":[NSNumber numberWithLong:self.patch.patchFile.rejects]};
    } else {
        [command setScriptErrorNumber:kAScriptFileError];
        [command setScriptErrorString:@"File not found"];
        [command setScriptErrorOffendingObjectDescriptor:[NSAppleEventDescriptor descriptorWithString:path]];
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
        [temp filterUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[c] %@", [sender stringValue]]];
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
    [[NSApp delegate] showSummary:sender];
}
-(IBAction)hexConvert:(id)sender{
    //TODO: hex converter popup or sheet
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
-(void)setDocument:(NSString *)string{
    [text setAttributedString:[[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:[NSFontManager.sharedFontManager selectedFont]}]];
    if (colorize) [colorize observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
    else [self performSelectorOnMainThread:@selector(textStorageDidProcessEditing:) withObject:nil waitUntilDone:false];
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
    [textView scrollRangeToVisible:range];
    [textView showFindIndicatorForRange:[text.string lineRangeForRange:range]];
}
#pragma mark NSTextStorageDelegate
-(void)textStorageDidProcessEditing:(NSNotification *)notification{
    [colorize textStorageDidProcessEditing:notification];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(buildNav) object:nil];
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
