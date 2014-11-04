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
typedef NS_ENUM(NSUInteger, PatchFileState) {
    PatchFileStateEmpty,
    PatchFileStatePreviewable,
    PatchFileStateAppliable,
    PatchFileStateApplying,
    PatchFileStateApplied
};

typedef NS_ENUM(NSUInteger, PatchScope) {
    PatchScopeAll,
    PatchScopeDefinitionblock,
    PatchScopeScope,
    PatchScopeMethod,
    PatchScopeDevice,
    PatchScopeProcessor,
    PatchScopeThermalzone
};

typedef NS_ENUM(NSUInteger, PatchMatch) {
    PatchMatchLabel,
    PatchMatchAddress,
    PatchMatchHID,
    PatchMatchRegex,
    PatchMatchRegexNot,
    PatchMatchParentLabel,
    PatchMatchParentType,
    PatchMatchParentAddress,
    PatchMatchParentHID
};

typedef NS_ENUM(NSUInteger, PatchAction) {
    PatchActionInsert,
    PatchActionSetLabel,
    PatchActionReplaceMatched,
    PatchActionReplaceallMatched,
    PatchActionRemoveMatched,
    PatchActionRemoveallMatched,
    PatchActionRemoveEntry,
    PatchActionReplaceContent,
    PatchActionStoreEight,
    PatchActionStoreNine
};

@interface PatchDelta : NSObject

@property (readonly) NSRange before;
@property (readonly) NSString *after;

@end

@interface PatchPredicate : NSObject

@property (readonly) PatchMatch match;
@property (readonly) id selector;

@end

@interface Patch : NSObject
@property (readonly) bool all;
@property (readonly) PatchScope scope;
@property (readonly) NSArray *predicates;
@property (readonly) PatchAction action;
@property (readonly) NSString *argument;

@end

@interface PatchFile : NSObject

@property (readonly) PatchFileState state;
@property (readonly) NSString *legend;
@property (readonly) NSArray *preview;
@property (readonly) NSDictionary *results;

+(NSDictionary *)fieldsForPatch:(NSString *)patch;
-(instancetype)initWithPatch:(NSString *)patch;
-(void)patchTextView:(NSTextView *)view apply:(bool)apply;

@end

@interface Patcher : NSObject <NSWindowDelegate, NSTextViewDelegate, NSTableViewDelegate>

@property (readonly) bool busy;
@property (nonatomic) NSString *patch;
@property (readonly) PatchFile *patchFile;

+(NSString *)entab:(NSString *)line with:(NSString *)previous;

-(instancetype)initWithTextView:(NSTextView *)textView;

-(IBAction)show:(id)sender;

@end
