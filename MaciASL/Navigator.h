//
//  Navigator.h
//  MaciASL
//
//  Created by PHPdev32 on 9/28/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface NavObject : NSObject

/*! \brief The ACPI name of the receiver
 *
 */
@property (readonly) NSString *name;

/*! \brief The complete textual range of the receiver
 *
 */
@property (readonly) NSRange range;

/*! \brief The range of content (within braces) of the receiver
 *
 * \param text The string on which to perform the lookup
 * \returns The range of the receiver contained by the first left brace, and the last right brace
 */
-(NSRange)contentRange:(NSString *)text;

@end

@interface Scope : NavObject

/*! \brief The hierarchical, and flattened children of the receiver
 *
 */
@property (readonly) NSArray *children, *flat;

/*! \brief Checks that the given range is part of the receiver
 *
 * \param check The range to check
 * \returns A boolean representing whether or not the given range is contained by the receiver, but not by its children
 */
-(bool)isSelf:(NSRange)check;

@end

@interface DefinitionBlock : Scope

/*! \brief Returns the empty initializer DefinitionBlock
 *
 */
+(DefinitionBlock *)emptyBlock;

/*! \brief Parses the string into a tree of NavObjects
 *
 * \param dsl The disassembled machine language string to parse
 * \returns The root DefinitionBlock object, populated with children
 */
+(DefinitionBlock *)build:(NSString *)dsl;

/*! \brief Filters the receiver
 *
 * \param filter The String used to filter the receiver
 * \returns A copy of the receiver, filtered and flatten for searching
 */
-(DefinitionBlock *)filteredWithString:(NSString *)filter;

@end
