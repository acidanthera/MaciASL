//
//  Patch.m
//  MaciASL
//
//  Created by PHPdev32 on 10/1/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Source.h"
#import "Patch.h"
#import "Document.h"
#import "Navigator.h"

@implementation PatchPredicate

-(instancetype)initWithMatch:(PatchMatch)match selector:(id)selector {
    self = [super init];
    if (self) {
        _match = match;
        _selector = selector;
    }
    return self;
}

@end

@implementation PatchDelta

-(instancetype)initWithBefore:(NSRange)range after:(NSString *)string {
    self = [super init];
    if (self) {
        _before = range;
        _after = string;
    }
    return self;
}

@end

@implementation Patch
static NSCharacterSet *white;
static NSRegularExpression *template;

+(void)load {
    white = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    template = [NSRegularExpression regularExpressionWithPattern:@"%(\\d+)" options:0 error:nil];
}

-(instancetype)initWithAll:(bool)all scope:(PatchScope)scope predicates:(NSArray *)predicates action:(PatchAction)action argument:(NSString *)argument {
    self = [super init];
    if (self) {
        _all = all;
        _scope = scope;
        _predicates = predicates;
        _action = action;
        _argument = argument;
    }
    return self;
}

+(NSString *)unescape:(NSString *)template {
    return [[[template stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
}

-(NSString *)argAsTemplate:(NSString *)eight nine:(NSString *)nine {
    NSString *temp = [Patch unescape:_argument];
    if (eight) temp = [temp stringByReplacingOccurrencesOfString:@"%8" withString:eight];
    if (nine) temp = [temp stringByReplacingOccurrencesOfString:@"%9" withString:nine];
    return [template stringByReplacingMatchesInString:temp options:0 range:NSMakeRange(0, temp.length) withTemplate:@"\\$$1"];
}

-(NSString *)argAsInsertion:(NSString *)line {
    NSMutableString *temp = [@"\n" mutableCopy];
    for (__strong NSString *ln in [[Patch unescape:_argument] componentsSeparatedByString:@"\n"]) {
        ln = [ln stringByTrimmingCharactersInSet:white];
        if (!ln.length) continue;
        line = [[Patcher entab:ln with:line] stringByAppendingFormat:@"%@\n",ln];
        [temp appendString:line];
    }
    return [temp copy];
}

@end

@implementation PatchFile {
    @private
    NSUInteger _rejects;
    NSMutableString *_text;
    NSString *_eight, *_nine;
    NSArray *_patches, *_changes;
}

static NSDictionary *black;
static NSArray *extents;
static NSArray *scopes;
static NSArray *predicates;
static NSArray *actions;
static NSCharacterSet *set;
static NSRegularExpression *lbl;
static NSRegularExpression *adr;
static NSRegularExpression *hid;

+(void)load {
    black = @{NSForegroundColorAttributeName:NSColor.blackColor};
    extents = @[@"into", @"into_all"];
    scopes = @[@"all", @"definitionblock", @"scope", @"method", @"device", @"processor", @"thermalzone"];
    predicates = @[@"label", @"name_adr", @"name_hid", @"code_regex", @"code_regex_not", @"parent_label", @"parent_type", @"parent_adr", @"parent_hid"];
    actions = @[@"insert", @"set_label", @"replace_matched", @"replaceall_matched", @"remove_matched", @"removeall_matched", @"remove_entry", @"replace_content", @"store_%8", @"store_%9"];
    set = [NSCharacterSet characterSetWithCharactersInString:@" \n"];
    lbl = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(?:%@)\\s*\\(\\s*([^\\s),]+)", [[scopes subarrayWithRange:NSMakeRange(1, scopes.count-1)] componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:nil];
    adr = [NSRegularExpression regularExpressionWithPattern:@"Name\\s*\\(\\s*\\_ADR\\s*,\\s*(.*)\\s*\\)" options:0 error:nil];
    hid = [NSRegularExpression regularExpressionWithPattern:@"Name\\s*\\(\\s*\\_HID\\s*,\\s*(?:EISAID\\s*\\()?\"(.*)\"\\s*\\)?\\s*\\)" options:NSRegularExpressionCaseInsensitive error:nil];
}

-(instancetype)initWithPatch:(NSString *)text {
    if (!text.length)
        return nil;
    self = [super init];
    if (self) {
        NSMutableArray *patches = [NSMutableArray array];
        __autoreleasing NSString *token;
        NSScanner *scan = [NSScanner scannerWithString:[text stringByTrimmingCharactersInSet:set]];
        NSScanner *subscan;
        scan.charactersToBeSkipped = nil;
        while(![scan isAtEnd]){
            [scan scanString:@"\n" intoString:nil];
            if (![[scan.string substringFromIndex:scan.scanLocation].lowercaseString hasPrefix:@"into"]) {
                [scan scanUpToString:@"\n" intoString:nil];
                continue;
            }
            [scan scanUpToString:@";" intoString:&token];
            [scan scanString:@";" intoString:nil];
            subscan = [NSScanner scannerWithString:token];
            subscan.charactersToBeSkipped = nil;
            [subscan scanUpToCharactersFromSet:set intoString:&token];
            NSUInteger index = [extents indexOfObject:token.lowercaseString];
            if (index == NSNotFound) continue;
            bool all = (index == 1);
            [subscan scanCharactersFromSet:set intoString:nil];
            [subscan scanUpToCharactersFromSet:set intoString:&token];
            index = [scopes indexOfObject:token.lowercaseString];
            if (index == NSNotFound) continue;
            PatchScope scope = index;
            NSMutableArray *conditions = [NSMutableArray array];
            @try {
                while (![subscan isAtEnd]) {
                    [subscan scanCharactersFromSet:set intoString:nil];
                    [subscan scanUpToCharactersFromSet:set intoString:&token];
                    index = [predicates indexOfObject:token.lowercaseString];
                    if (index == NSNotFound) {
                        if (!conditions.count) @throw @"Missing predicates";
                        else break;
                    }
                    [subscan scanCharactersFromSet:set intoString:nil];
                    [subscan scanUpToCharactersFromSet:set intoString:&token];
                    id obj = token;
                    if (index == PatchMatchRegex || index == PatchMatchRegexNot) {
                        NSError *err;
                        if(!(obj = [NSRegularExpression regularExpressionWithPattern:token options:0 error:&err]) && ModalError(err))
                            @throw @"Bad Regex";
                    }
                    [conditions addObject:[[PatchPredicate alloc] initWithMatch:index selector:obj]];
                }
                index = [actions indexOfObject:token.lowercaseString];
                if (index == NSNotFound) continue;
                PatchAction action = index;
                NSString *argument;
                [subscan scanCharactersFromSet:set intoString:nil];
                @try {
                    if ([subscan isAtEnd])
                        switch ((PatchAction)index) {
                            case PatchActionRemoveMatched:
                            case PatchActionRemoveallMatched:
                            case PatchActionRemoveEntry:
                                @throw @"No arguments";
                                break;
                            case PatchActionStoreEight:
                            case PatchActionStoreNine:
                                if ([[conditions valueForKey:@"predicate"] containsObject:@(PatchMatchRegex)])
                                    @throw @"Storing Regex";
                                break;
                            case PatchActionInsert:
                            case PatchActionSetLabel:
                            case PatchActionReplaceContent:
                            case PatchActionReplaceMatched:
                            case PatchActionReplaceallMatched:
                                continue;
                                break;
                                
                        }
                    [subscan scanUpToCharactersFromSet:set intoString:&token];
                    if (![token.lowercaseString isEqualToString:@"begin"]) continue;
                    [subscan scanCharactersFromSet:set intoString:nil];
                    token = [subscan.string substringFromIndex:subscan.scanLocation];
                    if ([token isEqualToString:@"end"] || ![token.lowercaseString hasSuffix:@"end"]) continue;
                    argument = [token substringToIndex:token.length-4];
                } @catch (id obj) {}
                [patches addObject:[[Patch alloc] initWithAll:all scope:scope predicates:[conditions copy] action:action argument:argument]];
            } @catch (id obj) {}
        }
        _patches = patches;
        assignWithNotice(self, state, _patches.count ? PatchFileStatePreviewable : PatchFileStateEmpty);
    }
    return self;
}

-(void)patchTextView:(NSTextView *)view apply:(bool)apply {
    [self prepareWithTextView:view];
    if (_state == PatchFileStateAppliable && apply) {
        assignWithNotice(self, state, PatchFileStateApplying);
        [view.undoManager beginUndoGrouping];
        for (NSArray *changes in _changes)
            for (PatchDelta *change in changes)
                [view insertText:change.after replacementRange:change.before];
        [view.undoManager endUndoGrouping];
        assignWithNotice(self, state, PatchFileStateApplied);
    }
}

-(void)prepareWithTextView:(NSTextView *)view {
    if (_state != PatchFileStatePreviewable)
        return;
    _text = [view.textStorage.string mutableCopy];
    bool context = [NSUserDefaults.standardUserDefaults boolForKey:@"context"];
    _rejects = 0;
    NSMutableArray *temp = [NSMutableArray array];
    NSMutableArray *list = [NSMutableArray array];
    NSDictionary *red = @{NSFontAttributeName:NSFontManager.sharedFontManager.selectedFont, NSForegroundColorAttributeName:NSColor.redColor};
    for (Patch *patch in _patches) {
        DefinitionBlock *nav = [DefinitionBlock build:_text];
        NSMutableArray *results = [NSMutableArray array];
        NSMutableArray *exclusions = [NSMutableArray array];
        NSMutableArray *offsets = [NSMutableArray array];
        NSArray *deltas;
        @try { deltas = [self walk:nav of:nav with:patch]; }
        @catch (NSArray *result) { deltas = result; }
        for (PatchDelta *delta in deltas) {
            NSRange before = delta.before;
            NSInteger offset = 0;
            for (NSValue *point in offsets)
                if (point.pointValue.x < before.location+offset)
                    offset+=point.pointValue.y;
            for (NSValue *range in exclusions)
                if (NSLocationInRange(before.location, range.rangeValue) || NSLocationInRange(range.rangeValue.location, before)) {
                    before.location += offset;
                    [list addObject:@{@"before":[[NSAttributedString alloc] initWithString:[_text substringWithRange:before] attributes:red], @"after":[[NSAttributedString alloc] initWithString:delta.after attributes:red]}];
                    _rejects++;
                    before.location = NSNotFound;
                    break;
                }
            if (before.location == NSNotFound) continue;
            [exclusions addObject:[NSValue valueWithRange:delta.before]];
            before.location += offset;
            [list addObject:context?[self context:before with:delta.after]:@{@"before":[_text substringWithRange:before], @"after":delta.after}];
            [_text replaceCharactersInRange:before withString:delta.after];
            [results addObject:[[PatchDelta alloc] initWithBefore:before after:delta.after]];
            offset = (NSInteger)delta.after.length-(NSInteger)before.length;
            if (offset != 0)
                [offsets addObject:[NSValue valueWithPoint:NSMakePoint(before.location, offset)]];
        }
        if (!results.count) continue;
        [temp addObject:[results copy]];
    }
    _changes = [temp copy];
    assignWithNotice(self, preview, [list copy]);
    if (_changes.count)
        assignWithNotice(self, state, PatchFileStateAppliable);
}

-(NSDictionary *)context:(NSRange)range with:(NSString *)string {
    NSRange context = [_text lineRangeForRange:range];
    if (context.location && [_text characterAtIndex:range.location]!= '\n')
        context = NSMakeRange(context.location-1, context.length+1);
    if (_text.length > NSMaxRange(context))
        context.length++;
    context = [_text lineRangeForRange:context];
    NSMutableAttributedString *before = [[NSMutableAttributedString alloc] initWithString:[_text substringWithRange:context] attributes:@{NSFontAttributeName:NSFontManager.sharedFontManager.selectedFont, NSForegroundColorAttributeName:NSColor.grayColor}];
    NSMutableAttributedString *after = [[NSMutableAttributedString alloc] initWithAttributedString:before];
    range.location -= context.location;
    [before setAttributes:black range:range];
    [after replaceCharactersInRange:range withString:string];
    [after setAttributes:black range:NSMakeRange(range.location, string.length)];
    return @{@"before":[before copy], @"after":[after copy]};
}

-(NSArray *)walk:(Scope *)node of:(Scope *)parent with:(Patch *)patch {
    NSMutableArray *results = [NSMutableArray array];
    bool match = false;
    switch (patch.scope) {
        case PatchScopeAll:
            match = true;
            break;
        case PatchScopeDefinitionblock:
            match = ([node isMemberOfClass:[DefinitionBlock class]]);
            break;
        case PatchScopeScope:
            match = ([node isMemberOfClass:[Scope class]]);
            break;
        case PatchScopeMethod:
            match = ([node isMemberOfClass:[Method class]]);
            break;
        case PatchScopeDevice:
            match = ([node isMemberOfClass:[Device class]]);
            break;
        case PatchScopeProcessor:
            match = ([node isMemberOfClass:[Processor class]]);
            break;
        case PatchScopeThermalzone:
            match = ([node isMemberOfClass:[ThermalZone class]]);
            break;
    }
    if (match) {
        NSArray *result = [self patch:node of:parent with:patch];
        if (result) [results addObjectsFromArray:result];
    }
    for (Scope *child in node.children)
        @try { [results addObjectsFromArray:[self walk:child of:node with:patch]]; }
    @catch (NSArray *result) { @throw [results arrayByAddingObjectsFromArray:result]; }
    return [results copy];
}

-(NSArray *)patch:(Scope *)node of:(Scope *)parent with:(Patch *)patch {
    __block NSRange range;
    NSRegularExpression *reg;
    for (PatchPredicate *predicate in patch.predicates) {
        switch (predicate.match) {
            case PatchMatchRegex:
                reg = predicate.selector;
                if ([reg.pattern isEqualToString:@"."] && patch.action != PatchActionReplaceMatched && patch.action != PatchActionReplaceallMatched && patch.action != PatchActionRemoveMatched && patch.action != PatchActionRemoveallMatched)
                    break;
                range = [reg rangeOfFirstMatchInString:_text options:0 range:[node contentRange:_text]];
                if (range.location != NSNotFound && [node isSelf:range])
                    break;
                return nil;
            case PatchMatchRegexNot:
            {
                range = NSMakeRange(NSNotFound, 0);
                reg = predicate.selector;
                [reg enumerateMatchesInString:_text options:0 range:[node contentRange:_text] usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
                    if ([node isSelf:result.range]) {
                        range = result.range;
                        *stop = true;
                    }
                }];
                if (range.location == NSNotFound)
                    break;
                return nil;
            }
            case PatchMatchLabel:
                if ([node.name isEqualToString:predicate.selector])
                    break;
                return nil;
            case PatchMatchAddress:
                range = [[adr firstMatchInString:_text options:0 range:[node contentRange:_text]] rangeAtIndex:1];
                if ([[_text substringWithRange:range] isEqualToString:predicate.selector] && [node isSelf:range])
                    break;
                return nil;
            case PatchMatchHID:
                range = [[hid firstMatchInString:_text options:0 range:[node contentRange:_text]] rangeAtIndex:1];
                if ([[_text substringWithRange:range] isEqualToString:predicate.selector] && [node isSelf:range])
                    break;
                return nil;
            case PatchMatchParentAddress:
                range = [[adr firstMatchInString:_text options:0 range:[parent contentRange:_text]] rangeAtIndex:1];
                if ([[_text substringWithRange:range] isEqualToString:predicate.selector] && [parent isSelf:range])
                    break;
                return nil;
            case PatchMatchParentHID:
                range = [[hid firstMatchInString:_text options:0 range:[parent contentRange:_text]] rangeAtIndex:1];
                if ([[_text substringWithRange:range] isEqualToString:predicate.selector] && [parent isSelf:range])
                    break;
                return nil;
            case PatchMatchParentLabel:
                if ([parent.name isEqualToString:predicate.selector])
                    break;
                return nil;
            case PatchMatchParentType:
                if ([[NSStringFromClass([parent class]) lowercaseString] isEqualToString:[predicate.selector lowercaseString]])
                    break;
                return nil;
        }
    }
    NSArray *result;
    switch (patch.action) {
        case PatchActionInsert:
            range = NSMakeRange(NSMaxRange([node contentRange:_text]), 0);
            if ([_text characterAtIndex:NSMaxRange(range)]=='\n' && ++range.length)
                result = @[[[PatchDelta alloc] initWithBefore:range after:[patch argAsInsertion:lineForRange(_text, range)]]];
            else {
                NSString *insert = [patch argAsInsertion:lineForRange(_text, range)];
                result = @[[[PatchDelta alloc] initWithBefore:range after:[insert stringByAppendingString:[Patcher entab:@"}" with:lineForRange(insert, NSMakeRange(insert.length-1, 0))]]]];
            }
            break;
        case PatchActionReplaceContent:
            range = [node contentRange:_text];
            if (range.length)
                result = @[[[PatchDelta alloc] initWithBefore:range after:[patch argAsInsertion:lineForRange(_text, NSMakeRange(range.location-1, 0))]]];
            else {
                NSString *replace = [patch argAsInsertion:lineForRange(_text, NSMakeRange(range.location-1, 0))];
                result = @[[[PatchDelta alloc] initWithBefore:range after:[replace stringByAppendingString:[Patcher entab:@"}" with:lineForRange(replace, NSMakeRange(replace.length-1, 0))]]]];
            }
            break;
        case PatchActionSetLabel:
            result = @[[[PatchDelta alloc] initWithBefore:[[lbl firstMatchInString:_text options:0 range:node.range] rangeAtIndex:1] after:patch.argument]];
            break;
        case PatchActionReplaceMatched:
        case PatchActionReplaceallMatched:
        case PatchActionRemoveMatched:
        case PatchActionRemoveallMatched:
        {
            NSMutableArray *results = [NSMutableArray array];
            [reg enumerateMatchesInString:_text options:0 range:[node contentRange:_text] usingBlock:^void(NSTextCheckingResult *check, NSMatchingFlags flags, BOOL *stop){
                if (![node isSelf:check.range]) return;
                [results addObject:[[PatchDelta alloc] initWithBefore:check.range after:(patch.action == PatchActionRemoveMatched || patch.action == PatchActionRemoveallMatched)?@"":[reg replacementStringForResult:check inString:self->_text offset:0 template:[patch argAsTemplate:self->_eight nine:self->_nine]]]];
                if (patch.action == PatchActionReplaceMatched || patch.action == PatchActionRemoveMatched)
                    *stop = true;
            }];
            if (results.count) result = [results copy];
            break;
        }
        case PatchActionRemoveEntry:
            result = @[[[PatchDelta alloc] initWithBefore:node.range after:@""]];
            break;
        case PatchActionStoreEight:
        case PatchActionStoreNine:
            if (!reg)
                ModalError([NSError errorWithDomain:kMaciASLDomain code:kStoreError userInfo:@{NSLocalizedDescriptionKey:@"No Regular Expression", NSLocalizedRecoverySuggestionErrorKey:@"Tried to store without an expression."}]);
            else if (!reg.numberOfCaptureGroups)
                ModalError([NSError errorWithDomain:kMaciASLDomain code:kStoreError userInfo:@{NSLocalizedDescriptionKey:@"No Regular Expression Groups", NSLocalizedRecoverySuggestionErrorKey:@"Tried to store from an expression with no captured groups."}]);
            else if (patch.action == PatchActionStoreEight)
                _eight = [NSRegularExpression escapedTemplateForString:[_text substringWithRange:[[reg firstMatchInString:_text options:0 range:[node contentRange:_text]] rangeAtIndex:1]]];
            else
                _nine = [NSRegularExpression escapedTemplateForString:[_text substringWithRange:[[reg firstMatchInString:_text options:0 range:[node contentRange:_text]] rangeAtIndex:1]]];
            break;
    }
    if (!patch.all && result) @throw result;
    return result;
}

#pragma mark Readonly Properties
+ (NSSet *)keyPathsForValuesAffectingLegend {
    return [NSSet setWithObjects:@"state", nil];
}

-(NSString *)legend {
    return [NSString stringWithFormat:@"%ld Patch%s, %ld Change%s, %ld Reject%s", _patches.count, (_patches.count == 1) ? "" : "es", _preview.count - _rejects, (_preview.count - _rejects == 1) ? "" : "s", _rejects, (_rejects == 1) ? "" : "s"];
}

-(NSDictionary *)results {
    return @{@"patches":[NSNumber numberWithLong:_patches.count], @"changes":[NSNumber numberWithLong:_preview.count - _rejects], @"rejects":[NSNumber numberWithLong:_rejects]};
}

@end

@implementation Patcher {
    @private
    IBOutlet NSWindow *_window;
    IBOutlet NSOutlineView *_sourceView;
    IBOutlet NSTextView *_patchView;
    __unsafe_unretained NSTextView *_textView;
}

#pragma mark Class
+(NSString *)entab:(NSString *)line with:(NSString *)previous {
    NSInteger tab = 0, offset = 0, i;
    while (tab < previous.length)
        if ([previous characterAtIndex:tab] == ' ') tab++;
        else break;
    i = tab;
    if ([line characterAtIndex:0] == '}') offset = -1;
    else if ([previous characterAtIndex:tab] == '/') ;
    else if ([previous characterAtIndex:tab] == '}') offset = 0;
    else while (i < previous.length)
        switch ([previous characterAtIndex:i++]) {
            case '{': offset++; break;
            case '}': offset--; break;
        }
    return [@"" stringByPaddingToLength:4*MAX(tab/4+MAX(MIN(offset, 1), -1), 0) withString:@" " startingAtIndex:0];
}

#pragma mark NSObject Lifecycle
-(instancetype)initWithTextView:(NSTextView *)textView {
    self = [super init];
    if (self) {
        LoadNib(@"Patch", self);
        _textView = textView;
        [SourceList.sharedList addObserver:self forKeyPath:@"providers" options:0 context:nil];
    }
    return self;
}

-(void)dealloc {
    [SourceList.sharedList removeObserver:self forKeyPath:@"providers" context:nil];
}

#pragma mark Actions
-(IBAction)show:(id)sender {
    [NSApp beginSheet:_window modalForWindow:_textView.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    SplitView([[_window.contentView subviews] objectAtIndex:0]);
    SplitView([[[[[[_window.contentView subviews] objectAtIndex:0] subviews] objectAtIndex:1] subviews] objectAtIndex:0]);
    _patchView.enabledTextCheckingTypes = 0;
    if (!_sourceView.sortDescriptors.count)
        _sourceView.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true selector:@selector(localizedStandardCompare:)]];
    [self expandTree:nil];
    [self previewPatch:nil];
}

-(IBAction)hide:(id)sender {
    [[[_window.contentView subviews] objectAtIndex:0] performSelector:@selector(adjustSubviews)];
    [[[[[[[_window.contentView subviews] objectAtIndex:0] subviews] objectAtIndex:1] subviews] objectAtIndex:0] performSelector:@selector(adjustSubviews)];
    [NSApp endSheet:_window];
    [_window orderOut:sender];
}

-(IBAction)applyPatch:(id)sender {
    if (_patchFile.state == PatchFileStateAppliable) {
        [_patchFile patchTextView:_textView apply:true];
        self.patch = nil;
    }
}

-(IBAction)openPatch:(id)sender {
    NSOpenPanel *open = [NSOpenPanel openPanel];
    if ([open runModal] == NSFileHandlingPanelOKButton)
        self.patch = [[NSString alloc] initWithContentsOfURL:open.URL encoding:NSUTF8StringEncoding error:NULL];
}

-(IBAction)choosePatch:(id)sender {
    if ([sender selectedRow] == -1 || ![[(NSTreeNode *)[sender itemAtRow:[sender selectedRow]] representedObject] isMemberOfClass:SourcePatch.class])
        return;
    NSURL *url = [[(NSTreeNode *)[sender itemAtRow:[sender selectedRow]] representedObject] url];
    if ([url.standardizedURL isEqualTo:url]) {
        [SourceList.sharedList UTF8StringWithContentsOfURL:url.standardizedURL completionHandler:^(NSString *response) {
            self.patch = response;
            [self->_window makeFirstResponder:self->_patchView];
        }];
        [sender deselectAll:sender];
    }
    else
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kURLStandardError userInfo:@{NSLocalizedDescriptionKey:@"URL Standardization Error", NSLocalizedRecoverySuggestionErrorKey:@"The URL provided could not be standardized and may be incorrect."}]);
}

-(IBAction)previewPatch:(id)sender {
    bool selection = (_patchView.selectedRange.length && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"]);
    assignWithNotice(self, busy, true);
    assignWithNotice(self, patchFile, [[PatchFile alloc] initWithPatch:selection ? [_patch substringWithRange:_patchView.selectedRange] : _patch]);
    if (_patchFile.state == PatchFileStatePreviewable) {
        [_patchFile patchTextView:_textView apply:false];
        if (_patchFile.state == PatchFileStateAppliable)
            assignWithNotice(self, busy, selection);
    }
}

-(IBAction)expandTree:(id)sender {
    [_sourceView expandItem:nil expandChildren:true];
}

#pragma mark Nonatomic Properties
-(void)setPatch:(NSString *)patch {
    _patch = patch;
    [Patcher cancelPreviousPerformRequestsWithTarget:self selector:@selector(previewPatch:) object:nil];
    [self performSelector:@selector(previewPatch:) withObject:nil afterDelay:1.5];
}

#pragma mark NSWindowDelegate
-(void)cancelOperation:(id)sender {
    if (_patchView.selectedRange.length && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"])
        _patchView.selectedRange = NSMakeRange(_patchView.selectedRange.location, 0);
    else
        [self hide:sender];
}

#pragma mark NSTableViewDelegate
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    NSInteger rows = tableView.tableColumns.count;
    CGFloat height = tableView.rowHeight;
    while (rows-- > 0)
        height = MAX([[tableView preparedCellAtColumn:rows row:row] cellSizeForBounds:NSMakeRect(0, 0, [[tableView.tableColumns objectAtIndex:rows] width], CGFLOAT_MAX)].height, height);
    return height;
}

#pragma mark NSTextViewDelegate
-(void)textViewDidChangeSelection:(NSNotification *)notification {
    if ((_patchView.selectedRange.length || [[notification.userInfo objectForKey:@"NSOldSelectedCharacterRange"] rangeValue].length) && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"])
        [self previewPatch:nil];
}

#pragma mark Observation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self performSelector:@selector(expandTree:) withObject:nil afterDelay:0];
}

@end
