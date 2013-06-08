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

@implementation Patcher

@synthesize window;
@synthesize busy;
@synthesize legend;
@synthesize patch;
@synthesize patchFile;
@synthesize patchView;
@synthesize sourceView;
@synthesize parent;

#pragma mark GUI
-(IBAction)apply:(id)sender{
    if (patchFile.state == applied) return;
    patchFile.state = applying;
    NSTextView *view = parent.textView;
    [view.undoManager beginUndoGrouping];
    for (NSArray *changes in patchFile.changes)
        for (PatchDelta *change in changes)
            [view insertText:change.after replacementRange:change.before];
    [view.undoManager endUndoGrouping];
    patchFile.state = applied;
    self.patch = nil;
}
-(IBAction)open:(id)sender{
    NSOpenPanel *open = [NSOpenPanel openPanel];
    if ([open runModal] != NSFileHandlingPanelOKButton) return;
    self.patch = [[NSString alloc] initWithData:[NSFileManager.defaultManager contentsAtPath:open.URL.path] encoding:NSUTF8StringEncoding];
}
-(IBAction)close:(id)sender{
    [[[window.contentView subviews] objectAtIndex:0] performSelector:@selector(adjustSubviews)];
    [[[[[[[window.contentView subviews] objectAtIndex:0] subviews] objectAtIndex:1] subviews] objectAtIndex:0] performSelector:@selector(adjustSubviews)];
    [NSApp endSheet:window];
    [window orderOut:sender];
}
-(IBAction)choosePatch:(id)sender{//TODO: python script bindings
    if ([sender selectedRow] == -1 || ![[[sender itemAtRow:[sender selectedRow]] representedObject] isMemberOfClass:[SourcePatch class]])
        return;
    NSURL *url = [[[sender itemAtRow:[sender selectedRow]] representedObject] url];
    if (![url.standardizedURL isEqualTo:url]) {
        ModalError([NSError errorWithDomain:kMaciASLDomain code:kURLStandardError userInfo:@{NSLocalizedDescriptionKey:@"URL Standardization Error", NSLocalizedRecoverySuggestionErrorKey:@"The URL provided could not be standardized and may be incorrect."}]);
        return;
    }
    AsynchFetch(url.standardizedURL, @selector(loadPatch:), self, nil);
    [sender deselectAll:sender];
}
-(void)loadPatch:(NSDictionary *)dict{
    self.patch = [dict objectForKey:@"response"];
    [window makeFirstResponder:patchView];
}

#pragma mark NSWindowDelegate
-(void)cancelOperation:(id)sender{
    if (patchView.selectedRange.length && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"])
        patchView.selectedRange = NSMakeRange(patchView.selectedRange.location, 0);
    else [self close:sender];
}

#pragma mark NSTableViewDelegate
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    NSInteger rows = tableView.tableColumns.count;
    CGFloat height = tableView.rowHeight;
    while (rows-- > 0)
        height = MAX([[tableView preparedCellAtColumn:rows row:row] cellSizeForBounds:NSMakeRect(0, 0, [[tableView.tableColumns objectAtIndex:rows] width], CGFLOAT_MAX)].height,height);
    return height;
}

#pragma mark NSTextViewDelegate
-(void)textViewDidChangeSelection:(NSNotification *)notification{
    if ((patchView.selectedRange.length || [[notification.userInfo objectForKey:@"NSOldSelectedCharacterRange"] rangeValue].length) && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"])
        [self preview];
}

#pragma mark Class
+(NSString *)entab:(NSString *)line with:(NSString *)previous{
    NSInteger tab = 0;
    while (tab < previous.length)
        if ([previous characterAtIndex:tab++] != ' ')
            break;
    NSInteger offset = CountCharInStr(previous, '{') + CountCharInStr(previous, '(') - CountCharInStr(previous, ')');
    if ([line hasPrefix:@"}"]) offset--;
    tab = (tab > 2)?((tab-3)/4)+1:0;
    return [@"" stringByPaddingToLength:4*MAX(tab+offset, 0) withString:@" " startingAtIndex:0];
}
+(Patcher *)create:(id)sender{
    Patcher *temp = [Patcher new];
    LoadNib(@"Patch", temp);
    temp.parent = sender;
    [temp addObserver:temp forKeyPath:@"patch" options:0 context:nil];
    [SourceList.sharedList addObserver:temp forKeyPath:@"providers" options:0 context:nil];
    return temp;
}
-(void)beginSheet{
    [NSApp beginSheet:window modalForWindow:[parent windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    SplitView([[window.contentView subviews] objectAtIndex:0]);
    SplitView([[[[[[window.contentView subviews] objectAtIndex:0] subviews] objectAtIndex:1] subviews] objectAtIndex:0]);
    patchView.enabledTextCheckingTypes = 0;
    [self expandTree];
    [self preview];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"patch"]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preview) object:nil];
        [self performSelector:@selector(preview) withObject:nil afterDelay:1.5];
    }
    else if ([keyPath isEqualToString:@"providers"])
        [self performSelector:@selector(expandTree) withObject:nil afterDelay:0];
}
-(void)expandTree{
    [sourceView expandItem:nil expandChildren:true];
}
-(void)preview{
    bool selection = (patchView.selectedRange.length && [NSUserDefaults.standardUserDefaults boolForKey:@"isolation"]);
    self.busy = true;
    self.legend = nil;
    self.patchFile = [PatchFile create:selection?[patch substringWithRange:patchView.selectedRange]:patch];
    if (!patchFile.patches.count) return;
    patchFile.text = [parent.text.string mutableCopy];
    [patchFile apply];
    self.legend = [NSString stringWithFormat:@"%ld Patch%s, %ld Change%s, %ld Reject%s", patchFile.patches.count, (patchFile.patches.count == 1)?"":"es", patchFile.preview.count-patchFile.rejects, (patchFile.preview.count-patchFile.rejects == 1)?"":"s", patchFile.rejects, (patchFile.rejects == 1)?"":"s"];
    if (!patchFile.preview.count) return;
    self.busy = selection;
}

@end

@implementation PatchFile//TODO: patch generation

static NSDictionary *black;
static NSArray *extents;
static NSArray *scopes;
static NSArray *predicates;
static NSArray *actions;
static NSCharacterSet *set;
static NSRegularExpression *lbl;
static NSRegularExpression *adr;
static NSRegularExpression *hid;

@synthesize patches;
@synthesize changes;
@synthesize rejects;
@synthesize preview;
@synthesize eight;
@synthesize nine;
@synthesize state;
@synthesize text;
+(void)initialize{
    black = @{NSForegroundColorAttributeName:[NSColor blackColor]};
    extents = @[@"into", @"into_all"];
    scopes = @[@"all", @"definitionblock", @"scope", @"method", @"device", @"processor", @"thermalzone"];
    predicates = @[@"label", @"name_adr", @"name_hid", @"code_regex", @"code_regex_not", @"parent_label", @"parent_type", @"parent_adr", @"parent_hid"];
    actions = @[@"insert", @"set_label", @"replace_matched", @"replaceall_matched", @"remove_matched", @"removeall_matched", @"remove_entry", @"replace_content", @"store_%8", @"store_%9"];
    set = [NSCharacterSet characterSetWithCharactersInString:@" \n"];
    lbl = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(?:%@)\\s*\\(\\s*([^\\s),]+)", [[scopes subarrayWithRange:NSMakeRange(1, scopes.count-1)] componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:nil];
    adr = [NSRegularExpression regularExpressionWithPattern:@"Name\\s*\\(\\s*\\_ADR\\s*,\\s*(.*)\\s*\\)" options:0 error:nil];
    hid = [NSRegularExpression regularExpressionWithPattern:@"Name\\s*\\(\\s*\\_HID\\s*,\\s*(?:EISAID\\s*\\()?\"(.*)\"\\s*\\)?\\s*\\)" options:NSRegularExpressionCaseInsensitive error:nil];
}
+(PatchFile *)create:(NSString *)patch{
    PatchFile *temp = [PatchFile new];
    if (!patch.length) return temp;
    NSMutableArray *patches = [NSMutableArray array];
    __autoreleasing NSString *token;
    NSScanner *scan = [NSScanner scannerWithString:[patch stringByTrimmingCharactersInSet:set]];
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
        Patch *patch = [Patch new];
        patch.all = (index == 1);
        [subscan scanCharactersFromSet:set intoString:nil];
        [subscan scanUpToCharactersFromSet:set intoString:&token];
        index = [scopes indexOfObject:token.lowercaseString];
        if (index == NSNotFound) continue;
        patch.scope = (enum scope)index;
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
                if (index == code_regex || index == code_regex_not) {
                    NSError *err;
                    if(!(obj = [NSRegularExpression regularExpressionWithPattern:token options:0 error:&err]) && ModalError(err))
                        @throw @"Bad Regex";
                }
                [conditions addObject:[PatchPredicate create:(enum predicate)index withSelector:obj]];
            }
            patch.predicates = [conditions copy];
            index = [actions indexOfObject:token.lowercaseString];
            if (index == NSNotFound) continue;
            patch.action = (enum action)index;
            [subscan scanCharactersFromSet:set intoString:nil];
            @try {
                if ([subscan isAtEnd])
                    switch (index) {
                        case remove_matched:
                        case removeall_matched:
                        case remove_entry:
                            @throw @"No arguments";
                            break;
                        case store_eight:
                        case store_nine:
                            if ([[patch.predicates valueForKey:@"predicate"] containsObject:@(code_regex)])
                                @throw @"Storing Regex";
                            break;
                        case insert:
                        case set_label:
                        case replace_content:
                        case replace_matched:
                        case replaceall_matched:
                            continue;
                            break;
                            
                    }
                [subscan scanUpToCharactersFromSet:set intoString:&token];
                if (![token.lowercaseString isEqualToString:@"begin"]) continue;
                [subscan scanCharactersFromSet:set intoString:nil];
                token = [subscan.string substringFromIndex:subscan.scanLocation];
                if ([token isEqualToString:@"end"] || ![token.lowercaseString hasSuffix:@"end"]) continue;
                patch.argument = [token substringToIndex:token.length-4];
            } @catch (id obj) {}
            [patches addObject:patch];
        } @catch (id obj) {}
    }
    temp.patches = patches;
    return temp;
}
-(void)apply{
    bool context = [NSUserDefaults.standardUserDefaults boolForKey:@"context"];
    rejects = 0;
    NSMutableArray *temp = [NSMutableArray array];
    NSMutableArray *list = [NSMutableArray array];
    NSDictionary *red = @{NSFontAttributeName:NSFontManager.sharedFontManager.selectedFont, NSForegroundColorAttributeName:[NSColor redColor]};
    for (Patch *patch in patches) {
        DefinitionBlock *nav = [DefinitionBlock build:text];
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
                    [list addObject:@{@"before":[[NSAttributedString alloc] initWithString:[text substringWithRange:before] attributes:red], @"after":[[NSAttributedString alloc] initWithString:delta.after attributes:red]}];
                    rejects++;
                    before.location = NSNotFound;
                    break;
                }
            if (before.location == NSNotFound) continue;
            [exclusions addObject:[NSValue valueWithRange:delta.before]];
            before.location += offset;
            [list addObject:context?[self context:before with:delta.after]:@{@"before":[text substringWithRange:before], @"after":delta.after}];
            [text replaceCharactersInRange:before withString:delta.after];
            [results addObject:[PatchDelta create:before withReplacement:delta.after]];
            offset = (NSInteger)delta.after.length-(NSInteger)before.length;
            if (offset != 0)
                [offsets addObject:[NSValue valueWithPoint:NSMakePoint(before.location, offset)]];
        }
        if (!results.count) continue;
        [temp addObject:[results copy]];
    }
    changes = [temp copy];
    self.preview = [list copy];
}
-(NSDictionary *)context:(NSRange)range with:(NSString *)string{
    NSRange context = [text lineRangeForRange:range];
    if (context.location && [text characterAtIndex:range.location]!= '\n')
        context = NSMakeRange(context.location-1, context.length+1);
    if (text.length > NSMaxRange(context))
        context.length++;
    context = [text lineRangeForRange:context];
    NSMutableAttributedString *before = [[NSMutableAttributedString alloc] initWithString:[text substringWithRange:context] attributes:@{NSFontAttributeName:NSFontManager.sharedFontManager.selectedFont, NSForegroundColorAttributeName:[NSColor grayColor]}];
    NSMutableAttributedString *after = [[NSMutableAttributedString alloc] initWithAttributedString:before];
    range.location -= context.location;
    [before setAttributes:black range:range];
    [after replaceCharactersInRange:range withString:string];
    [after setAttributes:black range:NSMakeRange(range.location, string.length)];
    return @{@"before":[before copy], @"after":[after copy]};
}
-(NSArray *)walk:(Scope *)node of:(Scope *)parent with:(Patch *)patch{
    NSMutableArray *results = [NSMutableArray array];
    bool match = false;
    switch (patch.scope) {
        case all:
            match = true;
            break;
        case definitionblock:
            match = ([node isMemberOfClass:[DefinitionBlock class]]);
            break;
        case scope:
            match = ([node isMemberOfClass:[Scope class]]);
            break;
        case method:
            match = ([node isMemberOfClass:[Method class]]);
            break;
        case device:
            match = ([node isMemberOfClass:[Device class]]);
            break;
        case processor:
            match = ([node isMemberOfClass:[Processor class]]);
            break;
        case thermalzone:
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
-(NSArray *)patch:(Scope *)node of:(Scope *)parent with:(Patch *)patch{
    __block NSRange range;
    NSRegularExpression *reg;
    for (PatchPredicate *predicate in patch.predicates) {
        switch (predicate.predicate) {
            case code_regex:
                reg = predicate.selector;
                if ([reg.pattern isEqualToString:@"."] && patch.action != replace_matched && patch.action != replaceall_matched && patch.action != remove_matched && patch.action != removeall_matched)
                    break;
                range = [reg rangeOfFirstMatchInString:text options:0 range:[node contentRange:text]];
                if (range.location != NSNotFound && [node isSelf:range])
                    break;
                return nil;
            case code_regex_not:
            {
                range = NSMakeRange(NSNotFound, 0);
                reg = predicate.selector;
                [reg enumerateMatchesInString:text options:0 range:[node contentRange:text] usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
                    if ([node isSelf:result.range]) {
                        range = result.range;
                        *stop = true;
                    }
                }];
                if (range.location == NSNotFound)
                    break;
                return nil;
            }
            case label:
                if ([node.name isEqualToString:predicate.selector])
                    break;
                return nil;
            case name_adr:
                range = [[adr firstMatchInString:text options:0 range:[node contentRange:text]] rangeAtIndex:1];
                if ([[text substringWithRange:range] isEqualToString:predicate.selector] && [node isSelf:range])
                    break;
                return nil;
            case name_hid:
                range = [[hid firstMatchInString:text options:0 range:[node contentRange:text]] rangeAtIndex:1];
                if ([[text substringWithRange:range] isEqualToString:predicate.selector] && [node isSelf:range])
                    break;
                return nil;
            case parent_adr:
                range = [[adr firstMatchInString:text options:0 range:[parent contentRange:text]] rangeAtIndex:1];
                if ([[text substringWithRange:range] isEqualToString:predicate.selector] && [parent isSelf:range])
                    break;
                return nil;
            case parent_hid:
                range = [[hid firstMatchInString:text options:0 range:[parent contentRange:text]] rangeAtIndex:1];
                if ([[text substringWithRange:range] isEqualToString:predicate.selector] && [parent isSelf:range])
                    break;
                return nil;
            case parent_label:
                if ([parent.name isEqualToString:predicate.selector])
                    break;
                return nil;
            case parent_type:
                if ([[NSStringFromClass([parent class]) lowercaseString] isEqualToString:[predicate.selector lowercaseString]])
                    break;
                return nil;
        }
    }
    NSArray *result;
    switch (patch.action) {
        case insert:
            range = NSMakeRange(NSMaxRange([node contentRange:text]), 0);
            if ([text characterAtIndex:NSMaxRange(range)]=='\n' && range.length++)
            result = @[[PatchDelta create:range withReplacement:[patch argAsInsertion:lineForRange(text, range)]]];
            else {
                NSString *insert = [patch argAsInsertion:lineForRange(text, range)];
                result = @[[PatchDelta create:range withReplacement:[insert stringByAppendingString:[Patcher entab:@"}" with:lineForRange(insert, NSMakeRange(insert.length-1, 0))]]]];
            }
            break;
        case replace_content:
            range = [node contentRange:text];
            if (range.length)
                result = @[[PatchDelta create:range withReplacement:[patch argAsInsertion:lineForRange(text, NSMakeRange(range.location-1, 0))]]];
            else {
                NSString *replace = [patch argAsInsertion:lineForRange(text, NSMakeRange(range.location-1, 0))];
            result = @[[PatchDelta create:range withReplacement:[replace stringByAppendingString:[Patcher entab:@"}" with:lineForRange(replace, NSMakeRange(replace.length-1, 0))]]]];
            }
            break;
        case set_label:
            result = @[[PatchDelta create:[[lbl firstMatchInString:text options:0 range:node.range] rangeAtIndex:1] withReplacement:patch.argument]];
            break;
        case replace_matched:
        case replaceall_matched:
        case remove_matched:
        case removeall_matched:
        {
            __block NSMutableArray *results = [NSMutableArray array];
            [reg enumerateMatchesInString:text options:0 range:[node contentRange:text] usingBlock:^void(NSTextCheckingResult *check, NSMatchingFlags flags, BOOL *stop){
                if (![node isSelf:check.range]) return;
                [results addObject:[PatchDelta create:check.range withReplacement:(patch.action == remove_matched || patch.action == removeall_matched)?@"":[reg replacementStringForResult:check inString:text offset:0 template:[patch argAsTemplate:eight nine:nine]]]];
                if (patch.action == replace_matched || patch.action == remove_matched)
                    *stop = true;
            }];
            if (results.count) result = [results copy];
            break;
        }
        case remove_entry:
            result = @[[PatchDelta create:node.range withReplacement:@""]];
            break;
        case store_eight:
        case store_nine:
            if (!reg)
                ModalError([NSError errorWithDomain:kMaciASLDomain code:kStoreError userInfo:@{NSLocalizedDescriptionKey:@"No Regular Expression", NSLocalizedRecoverySuggestionErrorKey:@"Tried to store without an expression."}]);
            else if (!reg.numberOfCaptureGroups)
                ModalError([NSError errorWithDomain:kMaciASLDomain code:kStoreError userInfo:@{NSLocalizedDescriptionKey:@"No Regular Expression Groups", NSLocalizedRecoverySuggestionErrorKey:@"Tried to store from an expression with no captured groups."}]);
            else if (patch.action == store_eight)
                eight = [text substringWithRange:[[reg firstMatchInString:text options:0 range:[node contentRange:text]] rangeAtIndex:1]];
            else
                nine = [text substringWithRange:[[reg firstMatchInString:text options:0 range:[node contentRange:text]] rangeAtIndex:1]];
            break;
    }
    if (!patch.all && result) @throw result;
    return result;
}
@end

@implementation Patch
static NSRegularExpression *field;
static NSCharacterSet *white;
static NSRegularExpression *template;
@synthesize all;
@synthesize scope;
@synthesize predicates;
@synthesize action;
@synthesize argument;

+(void)initialize{
    field = [NSRegularExpression regularExpressionWithPattern:@"\n#(\\w+):(\\w+) (.*)" options:0 error:nil];
    white = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    template = [NSRegularExpression regularExpressionWithPattern:@"%(\\d+)" options:0 error:nil];
}
+(NSDictionary *)fields:(NSString *)patch{
    if (!patch) patch = @"";
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [field enumerateMatchesInString:patch options:0 range:NSMakeRange(0, patch.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        NSString *domain = [patch substringWithRange:[result rangeAtIndex:1]];
        if (![dict objectForKey:domain]) [dict setObject:[NSMutableDictionary dictionary] forKey:domain];
        [[dict objectForKey:domain] setObject:[patch substringWithRange:[result rangeAtIndex:3]] forKey:[patch substringWithRange:[result rangeAtIndex:2]]];
    }];
    for (NSString *key in dict)
        [dict setObject:[[dict objectForKey:key] copy] forKey:key];
    return [dict copy];
}
+(NSString *)unescape:(NSString *)template{
    return [[[template stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
}
-(NSString *)argAsTemplate:(NSString *)eight nine:(NSString *)nine{
    NSString *temp = [Patch unescape:argument];
    if (eight) temp = [temp stringByReplacingOccurrencesOfString:@"%8" withString:eight];
    if (nine) temp = [temp stringByReplacingOccurrencesOfString:@"%9" withString:nine];
    return [template stringByReplacingMatchesInString:temp options:0 range:NSMakeRange(0, temp.length) withTemplate:@"\\$$1"];
}
-(NSString *)argAsInsertion:(NSString *)line{
    NSMutableString *temp = [@"\n" mutableCopy];
    for (__strong NSString *ln in [[Patch unescape:argument] componentsSeparatedByString:@"\n"]) {
        ln = [ln stringByTrimmingCharactersInSet:white];
        if (!ln.length) continue;
        line = [[Patcher entab:ln with:line] stringByAppendingFormat:@"%@\n",ln];
        [temp appendString:line];
    }
    return [temp copy];
}

@end

@implementation PatchPredicate
@synthesize predicate;
@synthesize selector;

+(PatchPredicate *)create:(enum predicate)predicate withSelector:(id)selector{
    PatchPredicate *temp = [PatchPredicate new];
    temp.predicate = predicate;
    temp.selector = selector;
    return temp;
}

@end

@implementation PatchDelta
@synthesize before;
@synthesize after;
+(PatchDelta *)create:(NSRange)before withReplacement:(NSString *)after{
    PatchDelta *temp = [PatchDelta new];
    temp.before = before;
    temp.after = after;
    return temp;
}

@end