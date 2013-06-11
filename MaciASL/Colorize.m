//
//  Colorize.m
//  MaciASL
//
//  Created by PHPdev32 on 9/30/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Colorize.h"
#define ColorRGB(x,y,z) [NSColor colorWithCalibratedRed:x/255.0 green:y/255.0 blue:z/255.0 alpha:1]

@implementation Colorize

static NSArray *controls;
static NSArray *constants;
static NSArray *operators;
static NSArray *arguments;
static NSArray *resources;
static NSArray *keywords;
static NSArray *predefined;
static NSRegularExpression *regString;
static NSRegularExpression *regNumber;
static NSRegularExpression *regComment;
static NSRegularExpression *regOperator;
static NSRegularExpression *regOpNoArg;
static NSRegularExpression *regKeywords;
static NSRegularExpression *regResources;
static NSRegularExpression *regPredefined;
static NSDictionary *themes;

+(void)initialize{
    controls = @[@"External", @"Include"];
    constants = @[@"One", @"Ones", @"Revision", @"Zero"];
    operators = @[@"AccessAs", @"Acquire", @"Add", @"Alias", @"And", @"BankField", @"Break", @"BreakPoint", @"Buffer", @"Case", @"Concatenate", @"ConcatenateResTemplate", @"CondRefOf", @"Connection", @"Continue", @"CopyObject", @"CreateBitField", @"CreateByteField", @"CreateDWordField", @"CreateField", @"CreateQWordField", @"CreateWordField", @"DataTableRegion", @"Debug", @"Decrement", @"Default", @"DefinitionBlock", @"DeRefOf", @"Device", @"Divide", @"Eisaid", @"Else", @"ElseIf", @"Event", @"Fatal", @"Field", @"FindSetLeftBit", @"FindSetRightBit", @"FromBcd", @"Function", @"If", @"Increment", @"Index", @"IndexField", @"LAnd", @"LEqual", @"LGreater", @"LGreaterEqual", @"LLess", @"LLessEqual", @"LNot", @"LNotEqual", @"Load", @"LoadTable", @"LOr", @"Match", @"Method", @"Mid", @"Mod", @"Multiply", @"Mutex", @"Name", @"NAnd", @"Noop", @"NOr", @"Not", @"Notify", @"ObjectType", @"Offset", @"OperationRegion", @"Or", @"Package", @"PowerResource", @"Processor", @"RefOf", @"Release", @"Reset", @"Return", @"Scope", @"ShiftLeft", @"ShiftRight", @"Signal", @"SizeOf", @"Sleep", @"Stall", @"Store", @"Subtract", @"Switch", @"ThermalZone", @"Timer", @"ToBcd", @"ToBuffer", @"ToDecimalString", @"ToHexString", @"ToInteger", @"ToString", @"ToUuid", @"Unicode", @"Unload", @"Wait", @"While", @"XOr"];
    arguments = @[@"Arg0", @"Arg1", @"Arg2", @"Arg3", @"Arg4", @"Arg5", @"Arg6", @"Local0", @"Local1", @"Local2", @"Local3", @"Local4", @"Local5", @"Local6", @"Local7"];
    resources = @[@"ResourceTemplate", @"RawDataBuffer", @"DMA", @"DWordIO", @"DWordMemory", @"DWordSpace", @"EndDependentFn", @"ExtendedIO", @"ExtendedMemory", @"ExtendedSpace", @"FixedDma", @"FixedIO", @"GpioInt", @"GpioIo", @"I2cSerialBus", @"Interrupt", @"IO", @"IRQ", @"IRQNoFlags", @"Memory24", @"Memory32", @"Memory32Fixed", @"QWordIO", @"QWordMemory", @"QWordSpace", @"Register", @"SpiSerialBus", @"StartDependentFn", @"StartDependentFnNoPri", @"UartSerialBus", @"VendorLong", @"VendorShort", @"WordBusNumber", @"WordIO", @"WordSpace"];
    keywords = @[@"AttribQuick", @"AttribSendReceive", @"AttribByte", @"AttribWord", @"AttribBlock", @"AttribProcessCall", @"AttribBlockProcessCall", @"SMBQuick", @"SMBSendReceive", @"SMBByte", @"SMBWord", @"SMBBlock", @"SMBProcessCall", @"SMBBlockProcessCall", @"AnyAcc", @"ByteAcc", @"WordAcc", @"DWordAcc", @"QWordAcc", @"BufferAcc", @"AddressingMode7Bit", @"AddressingMode10Bit", @"AddressRangeMemory", @"AddressRangeReserved", @"AddressRangeNVS", @"AddressRangeACPI", @"BusMaster", @"NotBusMaster", @"DataBitsFive", @"DataBitsSix", @"DataBitsSeven", @"DataBitsEight", @"DataBitsNine", @"ClockPhaseFirst", @"ClockPhaseSecond", @"ClockPolarityLow", @"ClockPolarityHigh", @"PosDecode", @"SubDecode", @"Compatibility", @"TypeA", @"TypeB", @"TypeF", @"LittleEndian", @"BigEndian", @"AttribBytes", @"AttribRawBytes", @"AttribRawProcessBytes", @"FlowControlHardware", @"FlowControlNone", @"FlowControlXon", @"ActiveBoth", @"ActiveHigh", @"ActiveLow", @"Edge", @"Level", @"Decode10", @"Decode16", @"IoRestrictionNone", @"IoRestrictionInputOnly", @"IoRestrictionOutputOnly", @"IoRestrictionNoneAndPreserve", @"Lock", @"NoLock", @"MTR", @"MEQ", @"MLE", @"MLT", @"MGE", @"MGT", @"MaxFixed", @"MaxNotFixed", @"Cacheable", @"WriteCombining", @"Prefetchable", @"NonCacheable", @"MinFixed", @"MinNotFixed", @"UnknownObj", @"IntObj", @"StrObj", @"BuffObj", @"PkgObj", @"FieldUnitObj", @"DeviceObj", @"EventObj", @"MethodObj", @"MutexObj", @"OpRegionObj", @"PowerResObj", @"ProcessorObj", @"ThermalZoneObj", @"BuffFieldObj", @"DDBHandleObj", @"ParityTypeSpace", @"ParityTypeMark", @"ParityTypeOdd", @"ParityTypeEven", @"ParityTypeNone", @"PullDefault", @"PullUp", @"PullDown", @"PullNone", @"PolarityLow", @"PolarityHigh", @"ISAOnlyRanges", @"NonISAOnlyRanges", @"EntireRange", @"ReadWrite", @"ReadOnly", @"SystemIO", @"SystemMemory", @"PCI_Config", @"EmbeddedControl", @"SMBus", @"SystemCMOS", @"PciBarTarget", @"IPMI", @"GeneralPurposeIo", @"GenericSerialBus", @"PCC", @"FFixedHW", @"ResourceConsumer", @"ResourceProducer", @"Serialized", @"NotSerialized", @"Shared", @"Exclusive", @"SharedAndWake", @"ExclusiveAndWake", @"ControllerInitiated", @"DeviceInitiated", @"StopBitsOne", @"StopBitsOnePlusHalf", @"StopBitsTwo", @"StopBitsZero", @"Width8bit", @"Width16bit", @"Width32bit", @"Width64bit", @"Width128bit", @"Width256bit", @"SparseTranslation", @"DenseTranslation", @"TypeTranslation", @"TypeStatic", @"Preserve", @"WriteAsOnes", @"WriteAsZeros", @"FourWireMode", @"ThreeWireMode", @"Transfer8", @"Transfer8_16", @"Transfer16"];
    predefined = @[@"__DATE__", @"__FILE__", @"__LINE__", @"__PATH__"];
    regString = [NSRegularExpression regularExpressionWithPattern:@"\"[^\"]*\"" options:0 error:nil];
    regNumber = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(?<=\\W)(0x[0-9A-Fa-f]+|\\d+|%@)(?=\\W)", [constants componentsJoinedByString:@"|"]] options:0 error:nil];
    regComment = [NSRegularExpression regularExpressionWithPattern:@"//.*$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    regOperator = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(?<=\\W|^)(%@)\\s*\\(", [operators componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:nil];
    regOpNoArg = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\W(%@)\\W", [operators objectAtIndex:31]] options:0 error:nil];
    regKeywords = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\W(%@|%@)\\W", [keywords componentsJoinedByString:@"|"], [arguments componentsJoinedByString:@"|"]] options:0 error:nil];
    regResources = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\W(%@)\\W", [resources componentsJoinedByString:@"|"]] options:0 error:nil];
    regPredefined = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\W(%@|%@|%@)\\W", [[controls componentsJoinedByString:@"(?=\\s*\\()|"] stringByAppendingString:@"(?=\\s*\\()"], [predefined componentsJoinedByString:@"|"], [constants objectAtIndex:2]] options:0 error:nil];
    themes = @{@"Light":[ColorTheme create:[NSColor blackColor] background:[NSColor whiteColor] string:ColorRGB(196.0, 26.0, 22.0) number:ColorRGB(28.0,0,207.0) comment:ColorRGB(0,116.0,0) operator:ColorRGB(92.0,38.0,153.0) opNoArg:ColorRGB(92.0,38.0,153.0) keyword:ColorRGB(170.0,13.0,145.0) resource:ColorRGB(63.0,110.0,116.0) predefined:ColorRGB(100.0,56.0,32.0)], @"Dark":[ColorTheme create:[NSColor whiteColor] background:ColorRGB(30.0,32.0,40.0) string:ColorRGB(219.0,44.0,56.0) number:ColorRGB(120.0,109.0,196.0) comment:ColorRGB(65.0,182.0,69.0) operator:ColorRGB(0,160.0,190.0) opNoArg:ColorRGB(0,160.0,190.0) keyword:ColorRGB(178.0,24.0,137.0) resource:ColorRGB(131.0,192.0,87.0) predefined:ColorRGB(198.0,124.0,72.0)], @"Sunset":[ColorTheme create:[NSColor blackColor] background:ColorRGB(255.0,255.0,224.0) string:ColorRGB(226.0, 97.0, 2.0) number:ColorRGB(28.0,0,208.0) comment:ColorRGB(61.0, 149.0, 3.0) operator:ColorRGB(92.0,38.0,153.0) opNoArg:ColorRGB(92.0,38.0,153.0) keyword:ColorRGB(170.0,13.0,145.0) resource:ColorRGB(63.0,110.0,116.0) predefined:ColorRGB(100.0,56.0,32.0)]};
    muteWithNotice([NSApp delegate], themes, nil)
}

@synthesize view;
@synthesize mgr;
@synthesize theme;

+(Colorize *)create:(NSTextView *)view{
    Colorize *temp = [Colorize new];
    temp.view = view;
    temp.mgr = view.textContainer.layoutManager;
    [NSUserDefaults.standardUserDefaults addObserver:temp forKeyPath:@"theme" options:0 context:NULL];
    [NSUserDefaults.standardUserDefaults addObserver:temp forKeyPath:@"colorize" options:0 context:NULL];
    [temp observeValueForKeyPath:@"theme" ofObject:nil change:nil context:nil];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"colorize"]) [temp arm];
    return temp;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"colorize"]) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:keyPath]) {
            [self arm];
            [self colorize];
        }
        else [self disarm];
    }
    else if ([keyPath isEqualToString:@"theme"]) {
        if (!(theme = [themes objectForKey:[NSUserDefaults.standardUserDefaults stringForKey:@"theme"]]))
            theme = [themes.allKeys objectAtIndex:0];
        view.backgroundColor = theme.background;
        view.textColor = theme.text;
        view.insertionPointColor = theme.text;
    }
}

-(void)textStorageDidProcessEditing:(NSNotification *)notification{
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"colorize"]) return;
    [Colorize cancelPreviousPerformRequestsWithTarget:self selector:@selector(colorize) object:nil];
    [self performSelector:@selector(colorize) withObject:nil afterDelay:0.15];
}

-(void)colorize{
    NSRange range = [mgr characterRangeForGlyphRange:[mgr glyphRangeForBoundingRect:view.visibleRect inTextContainer:view.textContainer] actualGlyphRange:nil];
    [mgr removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    [regNumber enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.number forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regPredefined enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.predefined forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regKeywords enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.keyword forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regResources enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.resource forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regOperator enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.operator forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regOpNoArg enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.opNoArg forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regString enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.string forCharacterRange:result.range];
    }];
    [regComment enumerateMatchesInString:mgr.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.comment forCharacterRange:result.range];
    }];
    NSUInteger open = [mgr.attributedString.string rangeOfString:@"/*" options:0 range:range].location, close = [mgr.attributedString.string rangeOfString:@"*/" options:0 range:range].location;
    if (open == close) return;
    NSScanner *comments = [NSScanner scannerWithString:mgr.attributedString.string];
    comments.scanLocation = range.location;
    if (open < close) [comments scanUpToString:@"/*" intoString:nil];
    close = NSMaxRange(range);
    while (comments.scanLocation < close) {
        NSRange range;
        range.location = comments.scanLocation;
        [comments scanString:@"/*" intoString:nil];
        [comments scanUpToString:@"*/" intoString:nil];
        [comments scanString:@"*/" intoString:nil];
        range.length = comments.scanLocation-range.location;
        [mgr addTemporaryAttribute:NSForegroundColorAttributeName value:theme.comment forCharacterRange:range];
        [comments scanUpToString:@"/*" intoString:nil];
    }
}
-(void)arm {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSViewBoundsDidChangeNotification object:view.superview];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSViewFrameDidChangeNotification object:view.superview];
}
-(void)disarm {
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSViewBoundsDidChangeNotification object:view.superview];
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSViewFrameDidChangeNotification object:view.superview];
    [mgr removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, view.string.length)];
}

-(void)dealloc{
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"colorize"]) [self disarm];
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"colorize"];
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"theme"];
}
@end

@implementation ColorTheme
@synthesize background;
@synthesize text;
@synthesize string;
@synthesize number;
@synthesize comment;
@synthesize operator;
@synthesize opNoArg;
@synthesize keyword;
@synthesize resource;
@synthesize predefined;

+(NSDictionary *)allThemes{
    return themes;
}
+(ColorTheme *)create:(NSColor *)text background:(NSColor *)background string:(NSColor *)string number:(NSColor *)number comment:(NSColor *)comment operator:(NSColor *)operator opNoArg:(NSColor *)opNoArg keyword:(NSColor *)keyword resource:(NSColor *)resource predefined:(NSColor *)predefined{
    ColorTheme *temp = [ColorTheme new];
    temp.background = background;
    temp.text = text;
    temp.string = string;
    temp.number = number;
    temp.comment = comment;
    temp.operator = operator;
    temp.opNoArg = opNoArg;
    temp.keyword = keyword;
    temp.resource = resource;
    temp.predefined = predefined;
    return temp;
}

@end
