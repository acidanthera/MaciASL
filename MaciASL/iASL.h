//
//  iASL.h
//  MaciASL
//
//  Created by PHPdev32 on 9/27/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface iASLDecompilationResult : NSObject

@property (readonly) NSError *error;
@property (readonly) NSString *string;

@end

@interface iASLCompilationResult : iASLDecompilationResult

@property (readonly) NSArray *notices;
@property (readonly) NSURL *url;

@end

typedef NS_ENUM(NSUInteger, iASLNoticeType) {
    iASLNoticeTypeWarning,
    iASLNoticeTypeWarning2,
    iASLNoticeTypeWarning3,
    iASLNoticeTypeError,
    iASLNoticeTypeRemark,
    iASLNoticeTypeOptimization
};

@interface Notice : NSObject

@property (readonly) iASLNoticeType type;
@property (readonly) NSUInteger line, code;
@property (readonly) NSString *message;

@end

@interface iASL : NSObject

/*! \const The location of the system tableset
 *
 */
extern NSURL *const kSystemTableset;

+(NSString *)compiler;

+(NSUInteger)build;

/*! \brief Returns the system tableset
 *
 */
+(NSDictionary *)tableset;

/*! \brief Returns the array of device properties injected by the kernel and EFI
 *
 */
+(NSArray *)deviceProperties;

/*! \brief Returns the table injected by the given file URL's contents, or nil
 *
 * \param url The file URL whose contents will be checked
 * \returns The name of the table injected by the URL, or nil
 */
+(NSString *)isInjected:(NSURL *)url;

/*! \brief Returns the file used to inject the given table, or nil
 *
 * \param table The name of the table to check
 * \returns The file URL of the injected table, or nil
 */
+(NSURL *)wasInjected:(NSString *)table;

/*! \brief Returns an AML representation of a system table
 *
 * \param table The name of the table to return
 * \returns A Data representation of the system table
 */
+(NSData *)fetchTable:(NSString *)table;

/*! \brief Decompiles an AML representation to a DSL representation
 *
 * \param aml The AML representation of the table
 * \param name The name of the table, used to determine the type of table
 * \param tableset The tableset to be used in external symbol resolution
 * \param refs External reference file used passed to iasl
 * \returns The decompilation result
 */
+(iASLDecompilationResult *)decompileAML:(NSData *)aml name:(NSString *)name tableset:(NSURL *)tableset refs:(NSURL *)refs;

/*! \brief Compiles a DSL representation to an AML representation
 *
 * \param dsl The DSL representation of the table
 * \param name The name of the table, used to determine the type of table
 * \param tableset The tableset to be used in external symbol resolution
 * \param force Whether or not to force the compiler to produce a file, which may still fail
 * \returns The compilation result
 */
+(iASLCompilationResult *)compileDSL:(NSString *)dsl name:(NSString *)name tableset:(NSURL *)tableset force:(bool)force;

/*! \brief Creates a temp file
 *
 * \param template
 *
 * \returns temporary filename
 */
+(NSURL *)tempFile:(NSString *)template;

@end

@interface URLTask : NSObject

/*! \brief Fetches the remote URL, replacing the given path, and passing the success of the operation to the handler
 *
 * \param url The remote HTTP URL to fetch conditionally
 * \param file The file URL to replace
 * \param handler The block, dispatched on the main thread, which receives the success value of the operation
 */
+(void)get:(NSURL *)url toURL:(NSURL *)file perform:(void(^)(bool))handler;


/*! \brief Fetches the remote URL conditionally, replacing the given path, and passing the success of the operation to the handler
 *
 * \param url The remote HTTP URL to fetch conditionally
 * \param file The file URL to replace
 * \param handler The block, dispatched on the main thread, which receives the success value of the operation
 */
+(void)conditionalGet:(NSURL *)url toURL:(NSURL *)file perform:(void(^)(bool))handler;

@end
