//
//  Patch.h
//  MaciASL
//
//  Created by PHPdev32 on 10/1/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@class Document;
@class NavObject;

/* Patch Definition
 (into|into_all) (all|definitionBlock|scope|method|device|processor|thermalzone) [(label|name_adr|name_hid|code_regex|code_regex_not|parent_label|parent_type|parent_adr|parent_hid) <selector>...] (insert|set_label|replace_matched|replaceall_matched|remove_matched|removeall_matched|remove_entry|replace_content|store_%8|store_%9) [begin <argument> end];
 DOM
 extent     into,into_all
 scope      definitionblock,scope,method,device,processor,thermalzone,all
 predicate  label,name_adr,name_hid,parent_label,parent_type,parent_adr,parent_hid
 action     insert,set_label,remove_entry,replace_content
 
 REGEX
 extent     into,into_all
 predicate  code_regex,code_regex_not
 action     replace_matched,replaceall_matched,remove_matched,removeall_matched,store_%8,store_%9
 
 No Arguments
 remove_entry,remove_matched,removeall_matched,store_%8,store_%9
 
 single-line comments start with '#'
 patches separated by ';'
 */
enum state {
    notApplied,
    applying,
    applied
};

enum scope {
    all,
    definitionblock,
    scope,
    method,
    device,
    processor,
    thermalzone
};

enum predicate {
    label,
    name_adr,
    name_hid,
    code_regex,
    code_regex_not,
    parent_label,
    parent_type,
    parent_adr,
    parent_hid
};

enum action {
    insert,
    set_label,
    replace_matched,
    replaceall_matched,
    remove_matched,
    removeall_matched,
    remove_entry,
    replace_content,
    store_eight,
    store_nine
};

@interface PatchFile : NSObject

@property enum state state;
@property NSUInteger rejects;
@property NSMutableString *text;
@property NSString *eight;
@property NSString *nine;
@property NSArray *patches;
@property NSArray *preview;
@property NSArray *changes;

+(PatchFile *)create:(NSString *)patch;
-(void)apply;

@end

@interface Patcher : NSObject <NSWindowDelegate, NSTextViewDelegate, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *sourceView;
@property (strong) IBOutlet NSTextView *patchView;
@property bool busy;
@property NSString *legend;
@property NSString *patch;
@property PatchFile *patchFile;
@property Document *parent;

-(IBAction)open:(id)sender;
-(IBAction)apply:(id)sender;
-(IBAction)close:(id)sender;
-(IBAction)choosePatch:(id)sender;

+(NSString *)entab:(NSString *)line with:(NSString *)previous;
+(Patcher *)create:(id)sender;
-(void)beginSheet;
-(void)preview;

@end

@interface Patch : NSObject

@property bool all;
@property enum scope scope;
@property NSArray *predicates;
@property enum action action;
@property NSString *argument;

+(NSDictionary *)fields:(NSString *)patch;
+(NSString *)unescape:(NSString *)template;
-(NSString *)argAsTemplate:(NSString *)eight nine:(NSString *)nine;
-(NSString *)argAsInsertion:(NSString *)line;

@end

@interface PatchPredicate : NSObject

@property enum predicate predicate;
@property id selector;

+(PatchPredicate *)create:(enum predicate)predicate withSelector:(id)selector;

@end

@interface PatchDelta : NSObject

@property NSRange before;
@property NSString *after;

+(PatchDelta *)create:(NSRange)before withReplacement:(NSString *)after;

@end