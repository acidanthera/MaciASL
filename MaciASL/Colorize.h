//
//  Colorize.h
//  MaciASL
//
//  Created by PHPdev32 on 9/30/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface ColorTheme : NSObject

/*! \brief The various colors assigned to the syntactic categories
 *
 */
@property (readonly) NSColor *background, *text, *string, *number, *comment, *operator, *opNoArg, *keyword, *resource, *predefined;

/*! \brief Returns a Dictionary containing the themes registered
 *
 */
+(NSDictionary *)allThemes;

@end

@interface Colorize : NSObject <NSTextStorageDelegate>

/*! \brief Initializes the receiver with the given TextView
 *
 * \param textView The TextView the receiver will control for the purposes of code coloring
 * \returns The initialized receiver
 */
-(instancetype)initWithTextView:(NSTextView *)textView;

@end
