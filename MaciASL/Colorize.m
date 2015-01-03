//
//  Colorize.m
//  MaciASL
//
//  Created by PHPdev32 on 9/30/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Colorize.h"
#import "AppDelegate.h"
#define ColorRGB(x,y,z) [NSColor colorWithCalibratedRed:x/255.0 green:y/255.0 blue:z/255.0 alpha:1]

@implementation ColorTheme
static NSDictionary *themes;

+(void)load {
    themes = @{@"Light":[[ColorTheme alloc] initWithColors:@[NSColor.blackColor, NSColor.whiteColor, ColorRGB(196.0, 26.0, 22.0), ColorRGB(28.0,0,207.0), ColorRGB(0,116.0,0), ColorRGB(92.0,38.0,153.0), ColorRGB(92.0,38.0,153.0), ColorRGB(170.0,13.0,145.0), ColorRGB(63.0,110.0,116.0), ColorRGB(100.0,56.0,32.0)]],
               @"Dark":[[ColorTheme alloc] initWithColors:@[NSColor.whiteColor, ColorRGB(30.0,32.0,40.0), ColorRGB(219.0,44.0,56.0), ColorRGB(120.0,109.0,196.0), ColorRGB(65.0,182.0,69.0), ColorRGB(0,160.0,190.0), ColorRGB(0,160.0,190.0), ColorRGB(178.0,24.0,137.0), ColorRGB(131.0,192.0,87.0), ColorRGB(198.0,124.0,72.0)]],
               @"Sunset":[[ColorTheme alloc] initWithColors:@[NSColor.blackColor, ColorRGB(255.0,255.0,224.0), ColorRGB(226.0, 97.0, 2.0), ColorRGB(28.0,0,208.0), ColorRGB(61.0, 149.0, 3.0), ColorRGB(92.0,38.0,153.0), ColorRGB(92.0,38.0,153.0), ColorRGB(170.0,13.0,145.0), ColorRGB(63.0,110.0,116.0), ColorRGB(100.0,56.0,32.0)]]};
}

+(NSDictionary *)allThemes {
    return themes;
}

-(instancetype)initWithColors:(NSArray *)colors {
    self = [super init];
    if (self) {
        _text = [colors objectAtIndex:0];
        _background = [colors objectAtIndex:1];
        _string = [colors objectAtIndex:2];
        _number = [colors objectAtIndex:3];
        _comment = [colors objectAtIndex:4];
        _operator = [colors objectAtIndex:5];
        _opNoArg = [colors objectAtIndex:6];
        _keyword = [colors objectAtIndex:7];
        _resource = [colors objectAtIndex:8];
        _predefined = [colors objectAtIndex:9];
    }
    return self;
}

@end

@implementation Colorize {
    @private
    __unsafe_unretained NSTextView *_view;
    __unsafe_unretained NSLayoutManager *_manager;
    ColorTheme *_theme;
}

static NSArray *controls, *constants, *operators, *arguments, *resources, *keywords, *predefined;
static NSRegularExpression *regString, *regNumber, *regComment, *regOperator, *regOpNoArg, *regKeywords, *regResources, *regPredefined;

+(void)load {
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
}

#pragma mark NSObject Lifecycle
-(instancetype)initWithTextView:(NSTextView *)textView {
    self = [super init];
    if (self) {
        _view = textView;
        _manager = textView.textContainer.layoutManager;
        [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"theme" options:NSKeyValueObservingOptionInitial context:NULL];
        [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"colorize" options:NSKeyValueObservingOptionInitial context:NULL];
    }
    return self;
}

-(void)dealloc {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"colorize"])
        [self disarm];
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"colorize"];
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"theme"];
}

#pragma mark Observation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"colorize"]) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:keyPath]) {
            [self arm];
            [self colorize];
        }
        else [self disarm];
    }
    else if ([keyPath isEqualToString:@"theme"]) {
        if (!(_theme = [themes objectForKey:[NSUserDefaults.standardUserDefaults stringForKey:keyPath]]))
            _theme = themes.allKeys.firstObject;
        _view.backgroundColor = _theme.background;
        _view.textColor = _theme.text;
        _view.insertionPointColor = _theme.text;
    }
}

#pragma mark NSTextStorageDelegate
-(void)textStorageDidProcessEditing:(NSNotification *)notification {
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"colorize"]) return;
    [Colorize cancelPreviousPerformRequestsWithTarget:self selector:@selector(colorize) object:nil];
    [self performSelector:@selector(colorize) withObject:nil afterDelay:0.15];
}

-(void)colorize {
    NSRange range = [_manager characterRangeForGlyphRange:[_manager glyphRangeForBoundingRect:_view.visibleRect inTextContainer:_view.textContainer] actualGlyphRange:nil];
    [_manager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    [regNumber enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.number forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regPredefined enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.predefined forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regKeywords enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.keyword forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regResources enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.resource forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regOperator enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.operator forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regOpNoArg enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.opNoArg forCharacterRange:[result rangeAtIndex:1]];
    }];
    [regString enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.string forCharacterRange:result.range];
    }];
    [regComment enumerateMatchesInString:_manager.attributedString.string options:0 range:range usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        [self->_manager addTemporaryAttribute:NSForegroundColorAttributeName value:self->_theme.comment forCharacterRange:result.range];
    }];
    NSUInteger open = [_manager.attributedString.string rangeOfString:@"/*" options:0 range:range].location, close = [_manager.attributedString.string rangeOfString:@"*/" options:0 range:range].location;
    if (open == close) return;
    NSScanner *comments = [NSScanner scannerWithString:_manager.attributedString.string];
    comments.scanLocation = range.location;
    if (open < close) [comments scanUpToString:@"/*" intoString:nil];
    close = NSMaxRange(range);
    while (comments.scanLocation < close) {
        range.location = comments.scanLocation;
        [comments scanString:@"/*" intoString:nil];
        [comments scanUpToString:@"*/" intoString:nil];
        [comments scanString:@"*/" intoString:nil];
        range.length = comments.scanLocation-range.location;
        [_manager addTemporaryAttribute:NSForegroundColorAttributeName value:_theme.comment forCharacterRange:range];
        [comments scanUpToString:@"/*" intoString:nil];
    }
}

-(void)arm {
    NSNotificationCenter *c = NSNotificationCenter.defaultCenter;
    [c addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSViewBoundsDidChangeNotification object:_view.superview];
    [c addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSViewFrameDidChangeNotification object:_view.superview];
}

-(void)disarm {
    NSNotificationCenter *c = NSNotificationCenter.defaultCenter;
    [c removeObserver:self name:NSViewBoundsDidChangeNotification object:_view.superview];
    [c removeObserver:self name:NSViewFrameDidChangeNotification object:_view.superview];
    [_manager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, _view.string.length)];
}

@end
