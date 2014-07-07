//
//  SSDT.h
//  MaciASL
//
//  Created by PHPdev32 on 1/8/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface SSDTGen : NSObject

/*! \brief Numbers representing the receiver's input values
 *
 * TDP stands for Thermal Design Power, MTF is the Maximum Turbo Frequency, cpufrequency is the operating frequency of the CPU, and logicalcpus is the number of logical (not physical) CPUs present
 */
@property NSNumber *tdp, *mtf, *cpufrequency, *logicalcpus;

/*! \brief The String representing the current generator
 *
 */
@property NSString *generator;

/*! \brief Returns the singleton SSDT generator
 *
 */
+(SSDTGen *)sharedGenerator;

/*! \brief Displays the receiver's window
 *
 * \param sender Not used
 */
-(IBAction)show:(id)sender;

@end
