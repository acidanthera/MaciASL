//
//  Navigator.h
//  MaciASL
//
//  Created by PHPdev32 on 9/28/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface NavObject : NSObject

@property (readonly) NSString *name;
@property (readonly) NSRange range;

-(NSRange)contentRange:(NSString *)text;

@end

@interface Scope : NavObject

@property (readonly) NSArray *children, *flat;

-(bool)isSelf:(NSRange)check;

@end

@interface DefinitionBlock : Scope

+(DefinitionBlock *)emptyBlock;
+(DefinitionBlock *)build:(NSString *)dsl;

/*! \brief Filters the receiver
 *
 * \param filter The String used to filter the receiver
 * \returns A copy of the receiver, filtered and flatten for searching
 */
-(DefinitionBlock *)filteredWithString:(NSString *)filter;

@end
