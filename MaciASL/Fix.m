//
//  Fix.m
//  MaciASL
//
//  Created by PHPdev32 on 11/22/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Fix.h"
#import "iASL.h"

@implementation Fix

+(NSString *)suggestionForNotice:(Notice *)notice{
    NSUInteger temp = notice.code%1000;
    switch ((enum messages)(([NSUserDefaults.standardUserDefaults integerForKey:@"acpi"] == 4) ? msg4[temp] : msg5[temp])) {
        case ASL_MSG_NAME_OPTIMIZATION:
            return @"";
    }
    return @"";
}


@end
