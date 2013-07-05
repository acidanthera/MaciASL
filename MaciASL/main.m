//
//  main.m
//  MaciASL
//
//  Created by PHPdev32 on 9/21/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    NSImage *temp = [[NSImage alloc] initByReferencingFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarUtilitiesFolderIcon.icns"];
    temp.name = @"ToolbarUtilitiesFolderIcon";
    return NSApplicationMain(argc, (const char **)argv);
}
