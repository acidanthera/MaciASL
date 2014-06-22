//
//  MaciASL_Tests.m
//  MaciASL Tests
//
//  Created by PHPdev32 on 6/19/14.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import <XCTest/XCTest.h>
#import "iASL.h"
#import "Patch.h"

static NSData *aml;
static NSString *dsl;
static NSTextView *view;
static const char *md5 = "\xf2\x27\xc2\xa3\xf9\x28\x70\x62\xb4\x3f\xad\xf5\xd8\x8a\xef\xa4";

@interface MaciASL_Tests : XCTestCase

@end

@implementation MaciASL_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    view.string = dsl;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

+ (void)setUp
{
    NSData *d = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://github.com/qemu/qemu/raw/master/pc-bios/acpi-dsdt.aml"]];
    SecTransformRef t = SecDigestTransformCreate(kSecDigestMD5, 0, NULL);
    SecTransformSetAttribute(t, kSecTransformInputAttributeName, (__bridge CFDataRef)d, NULL);
    if (!memcmp([(__bridge_transfer NSData *)SecTransformExecute(t, NULL) bytes], md5, 16)) {
        aml = d;
        view = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
        dsl = [[iASL decompileAML:aml name:@"DSDT" tableset:nil] string];
    }
}

- (void)testDecompileError
{
    iASLDecompilationResult *r = [iASL decompileAML:aml name:@"DSDT" tableset:nil];
    XCTAssertNil(r.error, @"Decompilation error %@", r.error);
}

- (void)testDecompileString
{
    iASLDecompilationResult *r = [iASL decompileAML:aml name:@"DSDT" tableset:nil];
    XCTAssertNotNil(r.string, @"Decompilation string empty");
}

- (void)testDecompileCompile
{
    iASLDecompilationResult *r = [iASL decompileAML:aml name:@"DSDT" tableset:nil];
    iASLCompilationResult *c = [iASL compileDSL:r.string name:@"DSDT" tableset:nil force:false];
    XCTAssertNil(c.error, @"Compilation error %@", c.error);
}

- (void)testPatchFile
{
    PatchFile *p = [[PatchFile alloc] initWithPatch:@"into device label LNKS set_label begin LNKA end"];
    XCTAssertEqual(p.state, PatchFileStatePreviewable, @"Patch not created");
}

- (void)testSmallPatchFile
{
    PatchFile *p = [[PatchFile alloc] initWithPatch:@"into device label LNKS set_label begin LNKA end"];
    [p patchTextView:view apply:false];
    XCTAssertEqual(p.preview.count, 1UL, @"Patch not created");
}

- (void)testMediumPatchFile
{
    PatchFile *p = [[PatchFile alloc] initWithPatch:@"into device label LNKS set_label begin LNKA end;into_all all label LNKA set_label begin LNKS end"];
    [p patchTextView:view apply:false];
    XCTAssertEqual(p.preview.count, 3UL, @"Patch not created");
}

- (void)testPatchTypes
{
    PatchFile *p = [[PatchFile alloc] initWithPatch:
                    @"into_all scope label 0x0000FFFF insert begin LNKA end;"
                    @"into scope name_adr 0x0000FFFF code_regex_not LNKS set_label begin LNKA end;"
                    @"into definitionblock name_hid 0x0000FFFF remove_entry;"
                    @"into method parent_label 0x0000FFFF replace_content begin LNKA end;"
                    @"into device label 0x0000FFFF code_regex LNKS replace_matched begin LNKA end;"
                    @"into thermalzone parent_type scope code_regex LNKS replaceall_matched begin LNKA end;"
                    @"into all parent_adr 0x0000FFFF code_regex LNKS remove_matched;"
                    @"into all parent_adr 0x0000FFFF code_regex LNKS store_%8;"
                    @"into all parent_adr 0x0000FFFF code_regex LNKS store_%9;"
                    @"into processor parent_hid 0x0000FFFF code_regex LNKS removeall_matched"];
    XCTAssertEqual([[p.results objectForKey:@"patches"] unsignedIntegerValue], 10UL, @"Patches not parsed");
}

@end
