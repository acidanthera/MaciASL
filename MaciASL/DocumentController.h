//
//  DocumentController.h
//  MaciASL
//
//  Created by PHPdev32 on 10/14/13.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@class Document;

@interface DocumentController : NSDocumentController

@property (readonly) NSArray *tableNames;
@property NSUInteger tableSelection;

/*! \brief Returns a Document representing the system table of the given name
 *
 * \param name The name of the system table to use
 * \param save Whether or not to prompt the user to save the file first, preserving the initial binary representation
 * \returns A Document, or nil on failure
 */
-(Document *)newDocumentFromACPI:(NSString *)name saveFirst:(bool)save;

/*! \brief Formats a new Document with the given parameters
 *
 * \param text The textual DSL representation of the document
 * \param displayName The initial display name of the document
 * \param tableName The name of the table
 * \param tableset The tableset from which the document originated
 * \param display Whether or not to display the Document, initially
 * \returns A Document initialized with the given parameters, or nil on failure
 */
-(Document *)newDocument:(NSString *)text displayName:(NSString *)displayName tableName:(NSString *)tableName tableset:(NSURL *)tableset display:(bool)display;

@end
