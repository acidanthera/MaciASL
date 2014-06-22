//
//  SSDT.h
//  MaciASL
//
//  Created by PHPdev32 on 1/8/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface SSDTGen : NSObject

@property NSNumber *tdp, *mtf, *cpufrequency, *logicalcpus;
@property NSString *generator;

+(SSDTGen *)sharedGenerator;

-(IBAction)show:(id)sender;

@end
