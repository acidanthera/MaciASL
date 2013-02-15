//
//  Fix.h
//  MaciASL
//
//  Created by PHPdev32 on 11/22/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

enum messages {
    ASL_MSG_RESERVED,                   //
    ASL_MSG_ALIGNMENT,                  // Must be a multiple of alignment/granularity value
    ASL_MSG_ALPHANUMERIC_STRING,        // String must be entirely alphanumeric
    ASL_MSG_AML_NOT_IMPLEMENTED,        // Opcode is not implemented in compiler AML code generator
    ASL_MSG_ARG_COUNT_HI,               // Too many arguments
    ASL_MSG_ARG_COUNT_LO,               // Too few arguments
    ASL_MSG_ARG_INIT,                   // Method argument is not initialized
    ASL_MSG_BACKWARDS_OFFSET,           // Invalid backwards offset
    ASL_MSG_BUFFER_LENGTH,              // Effective AML buffer length is zero
    ASL_MSG_CLOSE,                      // Could not close file
    ASL_MSG_COMPILER_INTERNAL,          // Internal compiler error
    ASL_MSG_COMPILER_RESERVED,          // Use of compiler reserved name
    ASL_MSG_CONNECTION_MISSING,         // A Connection operator is required for this field SpaceId
    ASL_MSG_CONNECTION_INVALID,         // Invalid OpRegion SpaceId for use of Connection operator
    ASL_MSG_CONSTANT_EVALUATION,        // Could not evaluate constant expression
    ASL_MSG_CONSTANT_FOLDED,            // Constant expression evaluated and reduced
    ASL_MSG_CORE_EXCEPTION,             // From ACPI CA Subsystem
    ASL_MSG_DEBUG_FILE_OPEN,            // Could not open debug file
    ASL_MSG_DEBUG_FILENAME,             // Could not create debug filename
    ASL_MSG_DEPENDENT_NESTING,          // Dependent function macros cannot be nested
    ASL_MSG_DMA_CHANNEL,                // Invalid DMA channel (must be 0-7)
    ASL_MSG_DMA_LIST,                   // Too many DMA channels (8 max)
    ASL_MSG_DUPLICATE_CASE,             // Case value already specified
    ASL_MSG_DUPLICATE_ITEM,             // Duplicate value in list
    ASL_MSG_EARLY_EOF,                  // Premature end-of-file reached
    ASL_MSG_ENCODING_LENGTH,            // Package length too long to encode
    ASL_MSG_EX_INTERRUPT_LIST,          // Too many interrupts (255 max)
    ASL_MSG_EX_INTERRUPT_LIST_MIN,      // Too few interrupts (1 minimum required)
    ASL_MSG_EX_INTERRUPT_NUMBER,        // Invalid interrupt number (must be 32 bits)
    ASL_MSG_FIELD_ACCESS_WIDTH,         // Access width is greater than region size
    ASL_MSG_FIELD_UNIT_ACCESS_WIDTH,    // Access width of Field Unit extends beyond region limit
    ASL_MSG_FIELD_UNIT_OFFSET,          // Field Unit extends beyond region limit
    ASL_MSG_GPE_NAME_CONFLICT,          // Name conflicts with a previous GPE method
    ASL_MSG_HID_LENGTH,                 // _HID string must be exactly 7 or 8 characters
    ASL_MSG_HID_PREFIX,                 // _HID prefix must be all uppercase or decimal digits
    ASL_MSG_HID_SUFFIX,                 // _HID suffix must be all hex digits
    ASL_MSG_INCLUDE_FILE_OPEN,          // Could not open include file
    ASL_MSG_INPUT_FILE_OPEN,            // Could not open input file
    ASL_MSG_INTEGER_LENGTH,             // 64-bit integer in 32-bit table, truncating
    ASL_MSG_INTEGER_OPTIMIZATION,       // Integer optimized to single-byte AML opcode
    ASL_MSG_INTERRUPT_LIST,             // Too many interrupts (16 max)
    ASL_MSG_INTERRUPT_NUMBER,           // Invalid interrupt number (must be 0-15)
    ASL_MSG_INVALID_ACCESS_SIZE,        // Invalid AccessSize (Maximum is 4 - QWord access)
    ASL_MSG_INVALID_ADDR_FLAGS,         // Invalid combination of Length and Min/Max fixed flags
    ASL_MSG_INVALID_CONSTANT_OP,        // Invalid operator in constant expression (not type 3/4/5)
    ASL_MSG_INVALID_EISAID,             // EISAID string must be of the form "UUUXXXX" (3 uppercase, 4 hex digits)
    ASL_MSG_INVALID_ESCAPE,             // Invalid or unknown escape sequence
    ASL_MSG_INVALID_GRAN_FIXED,         // Granularity must be zero for fixed Min/Max
    ASL_MSG_INVALID_GRANULARITY,        // Granularity must be zero or a power of two minus one
    ASL_MSG_INVALID_LENGTH,             // Length is larger than Min/Max window
    ASL_MSG_INVALID_LENGTH_FIXED,       // Length is not equal to fixed Min/Max window
    ASL_MSG_INVALID_MIN_MAX,            // Address Min is greater than Address Max
    ASL_MSG_INVALID_OPERAND,            // Invalid operand
    ASL_MSG_INVALID_PERFORMANCE,        // Invalid performance/robustness value
    ASL_MSG_INVALID_PRIORITY,           // Invalid priority value
    ASL_MSG_INVALID_STRING,             // Invalid Hex/Octal Escape - Non-ASCII or NULL
    ASL_MSG_INVALID_TARGET,             // Target operand not allowed in constant expression
    ASL_MSG_INVALID_TIME,               // Time parameter too long (255 max)
    ASL_MSG_INVALID_TYPE,               // Invalid type
    ASL_MSG_INVALID_UUID,               // UUID string must be of the form "aabbccdd-eeff-gghh-iijj-kkllmmnnoopp"
    ASL_MSG_ISA_ADDRESS,                // Maximum 10-bit ISA address (0x3FF)
    ASL_MSG_LEADING_ASTERISK,           // Invalid leading asterisk
    ASL_MSG_LIST_LENGTH_LONG,           // Initializer list longer than declared package length
    ASL_MSG_LIST_LENGTH_SHORT,          // Initializer list shorter than declared package length
    ASL_MSG_LISTING_FILE_OPEN,          // Could not open listing file
    ASL_MSG_LISTING_FILENAME,           // Could not create listing filename
    ASL_MSG_LOCAL_INIT,                 // Method local variable is not initialized
    ASL_MSG_LOCAL_OUTSIDE_METHOD,       // Local or Arg used outside a control method
    ASL_MSG_LONG_LINE,                  // Splitting long input line
    ASL_MSG_MEMORY_ALLOCATION,          // Memory allocation failure
    ASL_MSG_MISSING_ENDDEPENDENT,       // Missing EndDependentFn() macro in dependent resource list
    ASL_MSG_MISSING_STARTDEPENDENT,     // Missing StartDependentFn() macro in dependent resource list
    ASL_MSG_MULTIPLE_DEFAULT,           // More than one Default statement within Switch construct
    ASL_MSG_MULTIPLE_TYPES,             // Multiple types
    ASL_MSG_NAME_EXISTS,                // Name already exists in scope
    ASL_MSG_NAME_OPTIMIZATION,          // NamePath optimized
    ASL_MSG_NAMED_OBJECT_IN_WHILE,      // Creating a named object in a While loop
    ASL_MSG_NESTED_COMMENT,             // Nested comment found
    ASL_MSG_NO_CASES,                   // No Case statements under Switch
    ASL_MSG_NO_REGION,                  // _REG has no corresponding Operation Region
    ASL_MSG_NO_RETVAL,                  // Called method returns no value
    ASL_MSG_NO_WHILE,                   // No enclosing While statement
    ASL_MSG_NON_ASCII,                  // Invalid characters found in file
    ASL_MSG_NON_ZERO,                   // Operand evaluates to zero
    ASL_MSG_NOT_EXIST,                  // Object does not exist
    ASL_MSG_NOT_FOUND,                  // Object not found or not accessible from scope
    ASL_MSG_NOT_METHOD,                 // Not a control method, cannot invoke
    ASL_MSG_NOT_PARAMETER,              // Not a parameter, used as local only
    ASL_MSG_NOT_REACHABLE,              // Object is not accessible from this scope
    ASL_MSG_NOT_REFERENCED,             // Namespace object is not referenced
    ASL_MSG_NULL_DESCRIPTOR,            // Min/Max/Length/Gran are all zero, but no resource tag
    ASL_MSG_NULL_STRING,                // Invalid zero-length (null) string
    ASL_MSG_OPEN,                       // Could not open file
    ASL_MSG_OUTPUT_FILE_OPEN,           // Could not open output AML file
    ASL_MSG_OUTPUT_FILENAME,            // Could not create output filename
    ASL_MSG_PACKAGE_LENGTH,             // Effective AML package length is zero
    ASL_MSG_PREPROCESSOR_FILENAME,      // Could not create preprocessor filename
    ASL_MSG_READ,                       // Could not read file
    ASL_MSG_RECURSION,                  // Recursive method call
    ASL_MSG_REGION_BUFFER_ACCESS,       // Host Operation Region requires BufferAcc access
    ASL_MSG_REGION_BYTE_ACCESS,         // Host Operation Region requires ByteAcc access
    ASL_MSG_RESERVED_ARG_COUNT_HI,      // Reserved method has too many arguments
    ASL_MSG_RESERVED_ARG_COUNT_LO,      // Reserved method has too few arguments
    ASL_MSG_RESERVED_METHOD,            // Reserved name must be a control method
    ASL_MSG_RESERVED_NO_RETURN_VAL,     // Reserved method should not return a value
    ASL_MSG_RESERVED_OPERAND_TYPE,      // Invalid object type for reserved name
    ASL_MSG_RESERVED_RETURN_VALUE,      // Reserved method must return a value
    ASL_MSG_RESERVED_USE,               // Invalid use of reserved name
    ASL_MSG_RESERVED_WORD,              // Use of reserved name
    ASL_MSG_RESOURCE_FIELD,             // Resource field name cannot be used as a target
    ASL_MSG_RESOURCE_INDEX,             // Missing ResourceSourceIndex (required)
    ASL_MSG_RESOURCE_LIST,              // Too many resource items (internal error)
    ASL_MSG_RESOURCE_SOURCE,            // Missing ResourceSource string (required)
    ASL_MSG_RESULT_NOT_USED,            // Result is not used, operator has no effect
    ASL_MSG_RETURN_TYPES,               // Not all control paths return a value
    ASL_MSG_SCOPE_FWD_REF,              // Forward references from Scope operator not allowed
    ASL_MSG_SCOPE_TYPE,                 // Existing object has invalid type for Scope operator
    ASL_MSG_SEEK,                       // Could not seek file
    ASL_MSG_SERIALIZED,                 // Control Method marked Serialized
    ASL_MSG_SINGLE_NAME_OPTIMIZATION,   // NamePath optimized to NameSeg (uses run-time search path)
    ASL_MSG_SOME_NO_RETVAL,             // Called method may not always return a value
    ASL_MSG_STRING_LENGTH,              // String literal too long
    ASL_MSG_SWITCH_TYPE,                // Switch expression is not a static Integer/Buffer/String data type, defaulting to Integer
    ASL_MSG_SYNC_LEVEL,                 // SyncLevel must be in the range 0-15
    ASL_MSG_SYNTAX,                     //
    ASL_MSG_TABLE_SIGNATURE,            // Invalid Table Signature
    ASL_MSG_TAG_LARGER,                 // ResourceTag larger than Field
    ASL_MSG_TAG_SMALLER,                // ResourceTag smaller than Field
    ASL_MSG_TIMEOUT,                    // Result is not used, possible operator timeout will be missed
    ASL_MSG_TOO_MANY_TEMPS,             // Method requires too many temporary variables (_T_x)
    ASL_MSG_UNKNOWN_RESERVED_NAME,      // Unknown reserved name
    ASL_MSG_UNREACHABLE_CODE,           // Statement is unreachable
    ASL_MSG_UNSUPPORTED,                // Unsupported feature
    ASL_MSG_UPPER_CASE,                 // Non-hex letters must be upper case
    ASL_MSG_VENDOR_LIST,                // Too many vendor data bytes (7 max)
    ASL_MSG_WRITE,                      // Could not write file
    ASL_MSG_RANGE,                      // Constant out of range
    ASL_MSG_BUFFER_ALLOCATION,          // Could not allocate line buffer
    ASL_MSG_DIRECTIVE_SYNTAX,           // Invalid directive syntax
    ASL_MSG_ENDIF_MISMATCH,             // Mismatched #endif
    ASL_MSG_ERROR_DIRECTIVE,            // #error
    ASL_MSG_EXISTING_NAME,              // Name is already defined
    ASL_MSG_INVALID_INVOCATION,         // Invalid macro invocation
    ASL_MSG_MACRO_SYNTAX,               // Invalid macro syntax
    ASL_MSG_TOO_MANY_ARGUMENTS,         // Too many macro arguments
    ASL_MSG_UNKNOWN_DIRECTIVE,          // Unknown directive
    ASL_MSG_UNKNOWN_PRAGMA,             // Unknown pragma
    ASL_MSG_BUFFER_ELEMENT,             // Invalid element in buffer initializer list
    ASL_MSG_DIVIDE_BY_ZERO,             // Expression contains divide-by-zero
    ASL_MSG_FLAG_VALUE,                 // Flag value is too large
    ASL_MSG_INTEGER_SIZE,               // Integer too large for target
    ASL_MSG_INVALID_EXPRESSION,         // Invalid expression
    ASL_MSG_INVALID_FIELD_NAME,         // Invalid Field Name
    ASL_MSG_INVALID_HEX_INTEGER,        // Invalid hex integer constant
    ASL_MSG_OEM_TABLE,                  // OEM table - unknown contents
    ASL_MSG_RESERVED_VALUE,             // Reserved field must be zero
    ASL_MSG_UNKNOWN_LABEL,              // Label is undefined
    ASL_MSG_UNKNOWN_SUBTABLE,           // Unknown subtable type
    ASL_MSG_UNKNOWN_TABLE,              // Unknown ACPI table signature
    ASL_MSG_ZERO_VALUE,                 // Value must be non-zero
    /* ACPI 4.0 Only */
    ASL_MSG_BITS_TO_BYTES,              // Field offset is in bits, but a byte offset is required
    ASL_MSG_BYTES_TO_BITS,              // Field offset is in bytes, but a bit offset is required
};

static int msg5[] = {
    ASL_MSG_RESERVED,                   //
    ASL_MSG_ALIGNMENT,                  // Must be a multiple of alignment/granularity value
    ASL_MSG_ALPHANUMERIC_STRING,        // String must be entirely alphanumeric
    ASL_MSG_AML_NOT_IMPLEMENTED,        // Opcode is not implemented in compiler AML code generator
    ASL_MSG_ARG_COUNT_HI,               // Too many arguments
    ASL_MSG_ARG_COUNT_LO,               // Too few arguments
    ASL_MSG_ARG_INIT,                   // Method argument is not initialized
    ASL_MSG_BACKWARDS_OFFSET,           // Invalid backwards offset
    ASL_MSG_BUFFER_LENGTH,              // Effective AML buffer length is zero
    ASL_MSG_CLOSE,                      // Could not close file
    ASL_MSG_COMPILER_INTERNAL,          // Internal compiler error
    ASL_MSG_COMPILER_RESERVED,          // Use of compiler reserved name
    ASL_MSG_CONNECTION_MISSING,         // A Connection operator is required for this field SpaceId
    ASL_MSG_CONNECTION_INVALID,         // Invalid OpRegion SpaceId for use of Connection operator
    ASL_MSG_CONSTANT_EVALUATION,        // Could not evaluate constant expression
    ASL_MSG_CONSTANT_FOLDED,            // Constant expression evaluated and reduced
    ASL_MSG_CORE_EXCEPTION,             // From ACPI CA Subsystem
    ASL_MSG_DEBUG_FILE_OPEN,            // Could not open debug file
    ASL_MSG_DEBUG_FILENAME,             // Could not create debug filename
    ASL_MSG_DEPENDENT_NESTING,          // Dependent function macros cannot be nested
    ASL_MSG_DMA_CHANNEL,                // Invalid DMA channel (must be 0-7)
    ASL_MSG_DMA_LIST,                   // Too many DMA channels (8 max)
    ASL_MSG_DUPLICATE_CASE,             // Case value already specified
    ASL_MSG_DUPLICATE_ITEM,             // Duplicate value in list
    ASL_MSG_EARLY_EOF,                  // Premature end-of-file reached
    ASL_MSG_ENCODING_LENGTH,            // Package length too long to encode
    ASL_MSG_EX_INTERRUPT_LIST,          // Too many interrupts (255 max)
    ASL_MSG_EX_INTERRUPT_LIST_MIN,      // Too few interrupts (1 minimum required)
    ASL_MSG_EX_INTERRUPT_NUMBER,        // Invalid interrupt number (must be 32 bits)
    ASL_MSG_FIELD_ACCESS_WIDTH,         // Access width is greater than region size
    ASL_MSG_FIELD_UNIT_ACCESS_WIDTH,    // Access width of Field Unit extends beyond region limit
    ASL_MSG_FIELD_UNIT_OFFSET,          // Field Unit extends beyond region limit
    ASL_MSG_GPE_NAME_CONFLICT,          // Name conflicts with a previous GPE method
    ASL_MSG_HID_LENGTH,                 // _HID string must be exactly 7 or 8 characters
    ASL_MSG_HID_PREFIX,                 // _HID prefix must be all uppercase or decimal digits
    ASL_MSG_HID_SUFFIX,                 // _HID suffix must be all hex digits
    ASL_MSG_INCLUDE_FILE_OPEN,          // Could not open include file
    ASL_MSG_INPUT_FILE_OPEN,            // Could not open input file
    ASL_MSG_INTEGER_LENGTH,             // 64-bit integer in 32-bit table, truncating
    ASL_MSG_INTEGER_OPTIMIZATION,       // Integer optimized to single-byte AML opcode
    ASL_MSG_INTERRUPT_LIST,             // Too many interrupts (16 max)
    ASL_MSG_INTERRUPT_NUMBER,           // Invalid interrupt number (must be 0-15)
    ASL_MSG_INVALID_ACCESS_SIZE,        // Invalid AccessSize (Maximum is 4 - QWord access)
    ASL_MSG_INVALID_ADDR_FLAGS,         // Invalid combination of Length and Min/Max fixed flags
    ASL_MSG_INVALID_CONSTANT_OP,        // Invalid operator in constant expression (not type 3/4/5)
    ASL_MSG_INVALID_EISAID,             // EISAID string must be of the form "UUUXXXX" (3 uppercase, 4 hex digits)
    ASL_MSG_INVALID_ESCAPE,             // Invalid or unknown escape sequence
    ASL_MSG_INVALID_GRAN_FIXED,         // Granularity must be zero for fixed Min/Max
    ASL_MSG_INVALID_GRANULARITY,        // Granularity must be zero or a power of two minus one
    ASL_MSG_INVALID_LENGTH,             // Length is larger than Min/Max window
    ASL_MSG_INVALID_LENGTH_FIXED,       // Length is not equal to fixed Min/Max window
    ASL_MSG_INVALID_MIN_MAX,            // Address Min is greater than Address Max
    ASL_MSG_INVALID_OPERAND,            // Invalid operand
    ASL_MSG_INVALID_PERFORMANCE,        // Invalid performance/robustness value
    ASL_MSG_INVALID_PRIORITY,           // Invalid priority value
    ASL_MSG_INVALID_STRING,             // Invalid Hex/Octal Escape - Non-ASCII or NULL
    ASL_MSG_INVALID_TARGET,             // Target operand not allowed in constant expression
    ASL_MSG_INVALID_TIME,               // Time parameter too long (255 max)
    ASL_MSG_INVALID_TYPE,               // Invalid type
    ASL_MSG_INVALID_UUID,               // UUID string must be of the form "aabbccdd-eeff-gghh-iijj-kkllmmnnoopp"
    ASL_MSG_ISA_ADDRESS,                // Maximum 10-bit ISA address (0x3FF)
    ASL_MSG_LEADING_ASTERISK,           // Invalid leading asterisk
    ASL_MSG_LIST_LENGTH_LONG,           // Initializer list longer than declared package length
    ASL_MSG_LIST_LENGTH_SHORT,          // Initializer list shorter than declared package length
    ASL_MSG_LISTING_FILE_OPEN,          // Could not open listing file
    ASL_MSG_LISTING_FILENAME,           // Could not create listing filename
    ASL_MSG_LOCAL_INIT,                 // Method local variable is not initialized
    ASL_MSG_LOCAL_OUTSIDE_METHOD,       // Local or Arg used outside a control method
    ASL_MSG_LONG_LINE,                  // Splitting long input line
    ASL_MSG_MEMORY_ALLOCATION,          // Memory allocation failure
    ASL_MSG_MISSING_ENDDEPENDENT,       // Missing EndDependentFn() macro in dependent resource list
    ASL_MSG_MISSING_STARTDEPENDENT,     // Missing StartDependentFn() macro in dependent resource list
    ASL_MSG_MULTIPLE_DEFAULT,           // More than one Default statement within Switch construct
    ASL_MSG_MULTIPLE_TYPES,             // Multiple types
    ASL_MSG_NAME_EXISTS,                // Name already exists in scope
    ASL_MSG_NAME_OPTIMIZATION,          // NamePath optimized
    ASL_MSG_NAMED_OBJECT_IN_WHILE,      // Creating a named object in a While loop
    ASL_MSG_NESTED_COMMENT,             // Nested comment found
    ASL_MSG_NO_CASES,                   // No Case statements under Switch
    ASL_MSG_NO_REGION,                  // _REG has no corresponding Operation Region
    ASL_MSG_NO_RETVAL,                  // Called method returns no value
    ASL_MSG_NO_WHILE,                   // No enclosing While statement
    ASL_MSG_NON_ASCII,                  // Invalid characters found in file
    ASL_MSG_NON_ZERO,                   // Operand evaluates to zero
    ASL_MSG_NOT_EXIST,                  // Object does not exist
    ASL_MSG_NOT_FOUND,                  // Object not found or not accessible from scope
    ASL_MSG_NOT_METHOD,                 // Not a control method, cannot invoke
    ASL_MSG_NOT_PARAMETER,              // Not a parameter, used as local only
    ASL_MSG_NOT_REACHABLE,              // Object is not accessible from this scope
    ASL_MSG_NOT_REFERENCED,             // Namespace object is not referenced
    ASL_MSG_NULL_DESCRIPTOR,            // Min/Max/Length/Gran are all zero, but no resource tag
    ASL_MSG_NULL_STRING,                // Invalid zero-length (null) string
    ASL_MSG_OPEN,                       // Could not open file
    ASL_MSG_OUTPUT_FILE_OPEN,           // Could not open output AML file
    ASL_MSG_OUTPUT_FILENAME,            // Could not create output filename
    ASL_MSG_PACKAGE_LENGTH,             // Effective AML package length is zero
    ASL_MSG_PREPROCESSOR_FILENAME,      // Could not create preprocessor filename
    ASL_MSG_READ,                       // Could not read file
    ASL_MSG_RECURSION,                  // Recursive method call
    ASL_MSG_REGION_BUFFER_ACCESS,       // Host Operation Region requires BufferAcc access
    ASL_MSG_REGION_BYTE_ACCESS,         // Host Operation Region requires ByteAcc access
    ASL_MSG_RESERVED_ARG_COUNT_HI,      // Reserved method has too many arguments
    ASL_MSG_RESERVED_ARG_COUNT_LO,      // Reserved method has too few arguments
    ASL_MSG_RESERVED_METHOD,            // Reserved name must be a control method
    ASL_MSG_RESERVED_NO_RETURN_VAL,     // Reserved method should not return a value
    ASL_MSG_RESERVED_OPERAND_TYPE,      // Invalid object type for reserved name
    ASL_MSG_RESERVED_RETURN_VALUE,      // Reserved method must return a value
    ASL_MSG_RESERVED_USE,               // Invalid use of reserved name
    ASL_MSG_RESERVED_WORD,              // Use of reserved name
    ASL_MSG_RESOURCE_FIELD,             // Resource field name cannot be used as a target
    ASL_MSG_RESOURCE_INDEX,             // Missing ResourceSourceIndex (required)
    ASL_MSG_RESOURCE_LIST,              // Too many resource items (internal error)
    ASL_MSG_RESOURCE_SOURCE,            // Missing ResourceSource string (required)
    ASL_MSG_RESULT_NOT_USED,            // Result is not used, operator has no effect
    ASL_MSG_RETURN_TYPES,               // Not all control paths return a value
    ASL_MSG_SCOPE_FWD_REF,              // Forward references from Scope operator not allowed
    ASL_MSG_SCOPE_TYPE,                 // Existing object has invalid type for Scope operator
    ASL_MSG_SEEK,                       // Could not seek file
    ASL_MSG_SERIALIZED,                 // Control Method marked Serialized
    ASL_MSG_SINGLE_NAME_OPTIMIZATION,   // NamePath optimized to NameSeg (uses run-time search path)
    ASL_MSG_SOME_NO_RETVAL,             // Called method may not always return a value
    ASL_MSG_STRING_LENGTH,              // String literal too long
    ASL_MSG_SWITCH_TYPE,                // Switch expression is not a static Integer/Buffer/String data type, defaulting to Integer
    ASL_MSG_SYNC_LEVEL,                 // SyncLevel must be in the range 0-15
    ASL_MSG_SYNTAX,                     //
    ASL_MSG_TABLE_SIGNATURE,            // Invalid Table Signature
    ASL_MSG_TAG_LARGER,                 // ResourceTag larger than Field
    ASL_MSG_TAG_SMALLER,                // ResourceTag smaller than Field
    ASL_MSG_TIMEOUT,                    // Result is not used, possible operator timeout will be missed
    ASL_MSG_TOO_MANY_TEMPS,             // Method requires too many temporary variables (_T_x)
    ASL_MSG_UNKNOWN_RESERVED_NAME,      // Unknown reserved name
    ASL_MSG_UNREACHABLE_CODE,           // Statement is unreachable
    ASL_MSG_UNSUPPORTED,                // Unsupported feature
    ASL_MSG_UPPER_CASE,                 // Non-hex letters must be upper case
    ASL_MSG_VENDOR_LIST,                // Too many vendor data bytes (7 max)
    ASL_MSG_WRITE,                      // Could not write file
    ASL_MSG_RANGE,                      // Constant out of range
    ASL_MSG_BUFFER_ALLOCATION,          // Could not allocate line buffer
    ASL_MSG_DIRECTIVE_SYNTAX,           // Invalid directive syntax
    ASL_MSG_ENDIF_MISMATCH,             // Mismatched #endif
    ASL_MSG_ERROR_DIRECTIVE,            // #error
    ASL_MSG_EXISTING_NAME,              // Name is already defined
    ASL_MSG_INVALID_INVOCATION,         // Invalid macro invocation
    ASL_MSG_MACRO_SYNTAX,               // Invalid macro syntax
    ASL_MSG_TOO_MANY_ARGUMENTS,         // Too many macro arguments
    ASL_MSG_UNKNOWN_DIRECTIVE,          // Unknown directive
    ASL_MSG_UNKNOWN_PRAGMA,             // Unknown pragma
    ASL_MSG_BUFFER_ELEMENT,             // Invalid element in buffer initializer list
    ASL_MSG_DIVIDE_BY_ZERO,             // Expression contains divide-by-zero
    ASL_MSG_FLAG_VALUE,                 // Flag value is too large
    ASL_MSG_INTEGER_SIZE,               // Integer too large for target
    ASL_MSG_INVALID_EXPRESSION,         // Invalid expression
    ASL_MSG_INVALID_FIELD_NAME,         // Invalid Field Name
    ASL_MSG_INVALID_HEX_INTEGER,        // Invalid hex integer constant
    ASL_MSG_OEM_TABLE,                  // OEM table - unknown contents
    ASL_MSG_RESERVED_VALUE,             // Reserved field must be zero
    ASL_MSG_UNKNOWN_LABEL,              // Label is undefined
    ASL_MSG_UNKNOWN_SUBTABLE,           // Unknown subtable type
    ASL_MSG_UNKNOWN_TABLE,              // Unknown ACPI table signature
    ASL_MSG_ZERO_VALUE                  // Value must be non-zero
};

static int msg4[] = {
    ASL_MSG_RESERVED,                   //
    ASL_MSG_ALPHANUMERIC_STRING,        // String must be entirely alphanumeric
    ASL_MSG_AML_NOT_IMPLEMENTED,        // Opcode is not implemented in compiler AML code generator
    ASL_MSG_ARG_COUNT_HI,               // Too many arguments
    ASL_MSG_ARG_COUNT_LO,               // Too few arguments
    ASL_MSG_ARG_INIT,                   // Method argument is not initialized
    ASL_MSG_BACKWARDS_OFFSET,           // Invalid backwards offset
    ASL_MSG_BITS_TO_BYTES,              // Field offset is in bits, but a byte offset is required
    ASL_MSG_BUFFER_LENGTH,              // Effective AML buffer length is zero
    ASL_MSG_BYTES_TO_BITS,              // Field offset is in bytes, but a bit offset is required
    ASL_MSG_CLOSE,                      // Could not close file
    ASL_MSG_COMPILER_INTERNAL,          // Internal compiler error
    ASL_MSG_CONSTANT_EVALUATION,        // Could not evaluate constant expression
    ASL_MSG_CONSTANT_FOLDED,            // Constant expression evaluated and reduced
    ASL_MSG_CORE_EXCEPTION,             // From ACPI CA Subsystem
    ASL_MSG_DEBUG_FILE_OPEN,            // Could not open debug file
    ASL_MSG_DEBUG_FILENAME,             // Could not create debug filename
    ASL_MSG_DEPENDENT_NESTING,          // Dependent function macros cannot be nested
    ASL_MSG_DMA_CHANNEL,                // Invalid DMA channel (must be 0-7)
    ASL_MSG_DMA_LIST,                   // Too many DMA channels (8 max)
    ASL_MSG_DUPLICATE_CASE,             // Case value already specified
    ASL_MSG_DUPLICATE_ITEM,             // Duplicate value in list
    ASL_MSG_EARLY_EOF,                  // Premature end-of-file reached
    ASL_MSG_ENCODING_LENGTH,            // Package length too long to encode
    ASL_MSG_EX_INTERRUPT_LIST,          // Too many interrupts (255 max)
    ASL_MSG_EX_INTERRUPT_LIST_MIN,      // Too few interrupts (1 minimum required)
    ASL_MSG_EX_INTERRUPT_NUMBER,        // Invalid interrupt number (must be 32 bits)
    ASL_MSG_FIELD_ACCESS_WIDTH,         // Access width is greater than region size
    ASL_MSG_FIELD_UNIT_ACCESS_WIDTH,    // Access width of Field Unit extends beyond region limit
    ASL_MSG_FIELD_UNIT_OFFSET,          // Field Unit extends beyond region limit
    ASL_MSG_INCLUDE_FILE_OPEN,          // Could not open include file
    ASL_MSG_INPUT_FILE_OPEN,            // Could not open input file
    ASL_MSG_INTEGER_LENGTH,             // 64-bit integer in 32-bit table, truncating
    ASL_MSG_INTEGER_OPTIMIZATION,       // Integer optimized to single-byte AML opcode
    ASL_MSG_INTERRUPT_LIST,             // Too many interrupts (16 max)
    ASL_MSG_INTERRUPT_NUMBER,           // Invalid interrupt number (must be 0-15)
    ASL_MSG_INVALID_CONSTANT_OP,        // Invalid operator in constant expression (not type 3/4/5)
    ASL_MSG_INVALID_EISAID,             // EISAID string must be of the form "UUUXXXX" (3 uppercase, 4 hex digits)
    ASL_MSG_INVALID_ESCAPE,             // Invalid or unknown escape sequence
    ASL_MSG_INVALID_OPERAND,            // Invalid operand
    ASL_MSG_INVALID_PERFORMANCE,        // Invalid performance/robustness value
    ASL_MSG_INVALID_PRIORITY,           // Invalid priority value
    ASL_MSG_INVALID_STRING,             // Invalid Hex/Octal Escape - Non-ASCII or NULL
    ASL_MSG_INVALID_TARGET,             // Target operand not allowed in constant expression
    ASL_MSG_INVALID_TIME,               // Time parameter too long (255 max)
    ASL_MSG_INVALID_TYPE,               // Invalid type
    ASL_MSG_INVALID_UUID,               // UUID string must be of the form "aabbccdd-eeff-gghh-iijj-kkllmmnnoopp"
    ASL_MSG_LIST_LENGTH_LONG,           // Initializer list longer than declared package length
    ASL_MSG_LIST_LENGTH_SHORT,          // Initializer list shorter than declared package length
    ASL_MSG_LISTING_FILE_OPEN,          // Could not open listing file
    ASL_MSG_LISTING_FILENAME,           // Could not create listing filename
    ASL_MSG_LOCAL_INIT,                 // Method local variable is not initialized
    ASL_MSG_LONG_LINE,                  // Splitting long input line
    ASL_MSG_MEMORY_ALLOCATION,          // Memory allocation failure
    ASL_MSG_MISSING_ENDDEPENDENT,       // Missing EndDependentFn() macro in dependent resource list
    ASL_MSG_MISSING_STARTDEPENDENT,     // Missing StartDependentFn() macro in dependent resource list
    ASL_MSG_MULTIPLE_TYPES,             // Multiple types
    ASL_MSG_NAME_EXISTS,                // Name already exists in scope
    ASL_MSG_NAME_OPTIMIZATION,          // NamePath optimized
    ASL_MSG_NESTED_COMMENT,             // Nested comment found
    ASL_MSG_NO_CASES,                   // No Case statements under Switch
    ASL_MSG_NO_RETVAL,                  // Called method returns no value
    ASL_MSG_NO_WHILE,                   // No enclosing While statement
    ASL_MSG_NON_ASCII,                  // Invalid characters found in file
    ASL_MSG_NOT_EXIST,                  // Object does not exist
    ASL_MSG_NOT_FOUND,                  // Object not found or not accessible from scope
    ASL_MSG_NOT_METHOD,                 // Not a control method, cannot invoke
    ASL_MSG_NOT_PARAMETER,              // Not a parameter, used as local only
    ASL_MSG_NOT_REACHABLE,              // Object is not accessible from this scope
    ASL_MSG_OPEN,                       // Could not open file
    ASL_MSG_OUTPUT_FILE_OPEN,           // Could not open output AML file
    ASL_MSG_OUTPUT_FILENAME,            // Could not create output filename
    ASL_MSG_PACKAGE_LENGTH,             // Effective AML package length is zero
    ASL_MSG_READ,                       // Could not read file
    ASL_MSG_RECURSION,                  // Recursive method call
    ASL_MSG_REGION_BUFFER_ACCESS,       // Host Operation Region requires BufferAcc access
    ASL_MSG_REGION_BYTE_ACCESS,         // Host Operation Region requires ByteAcc access
    ASL_MSG_RESERVED_ARG_COUNT_HI,      // Reserved method has too many arguments
    ASL_MSG_RESERVED_ARG_COUNT_LO,      // Reserved method has too few arguments
    ASL_MSG_RESERVED_METHOD,            // Reserved name must be a control method
    ASL_MSG_RESERVED_OPERAND_TYPE,      // Invalid object type for reserved name
    ASL_MSG_RESERVED_RETURN_VALUE,      // Reserved method must return a value
    ASL_MSG_RESERVED_USE,               // Invalid use of reserved name
    ASL_MSG_RESERVED_WORD,              // Use of reserved name
    ASL_MSG_RESOURCE_FIELD,             // Resource field name cannot be used as a target
    ASL_MSG_RESOURCE_INDEX,             // Missing ResourceSourceIndex (required)
    ASL_MSG_RESOURCE_LIST,              // Too many resource items (internal error)
    ASL_MSG_RESOURCE_SOURCE,            // Missing ResourceSource string (required)
    ASL_MSG_RETURN_TYPES,               // Not all control paths return a value
    ASL_MSG_SCOPE_FWD_REF,              // Forward references from Scope operator not allowed
    ASL_MSG_SCOPE_TYPE,                 // Existing object has invalid type for Scope operator
    ASL_MSG_SEEK,                       // Could not seek file
    ASL_MSG_SINGLE_NAME_OPTIMIZATION,   // NamePath optimized to NameSeg (uses run-time search path)
    ASL_MSG_SOME_NO_RETVAL,             // Called method may not always return a value
    ASL_MSG_SWITCH_TYPE,                // Switch expression is not a static Integer/Buffer/String data type, defaulting to Integer
    ASL_MSG_SYNC_LEVEL,                 // SyncLevel must be in the range 0-15
    ASL_MSG_SYNTAX,                     //
    ASL_MSG_TABLE_SIGNATURE,            // Invalid Table Signature
    ASL_MSG_TOO_MANY_TEMPS,             // Method requires too many temporary variables (_T_x)
    ASL_MSG_UNKNOWN_RESERVED_NAME,      // Unknown reserved name
    ASL_MSG_UNREACHABLE_CODE,           // Statement is unreachable
    ASL_MSG_UNSUPPORTED,                // Unsupported feature
    ASL_MSG_VENDOR_LIST,                // Too many vendor data bytes (7 max)
    ASL_MSG_WRITE,                      // Could not write file
    ASL_MSG_MULTIPLE_DEFAULT,           // More than one Default statement within Switch construct
    ASL_MSG_TIMEOUT,                    // Possible operator timeout is ignored
    ASL_MSG_RESULT_NOT_USED,            // Result is not used, operator has no effect
    ASL_MSG_NOT_REFERENCED,             // Namespace object is not referenced
    ASL_MSG_NON_ZERO,                   // Operand evaluates to zero
    ASL_MSG_STRING_LENGTH,              // String literal too long
    ASL_MSG_SERIALIZED,                 // Control Method marked Serialized
    ASL_MSG_COMPILER_RESERVED,          // Use of compiler reserved name
    ASL_MSG_NAMED_OBJECT_IN_WHILE,      // Creating a named object in a While loop
    ASL_MSG_LOCAL_OUTSIDE_METHOD        // Local or Arg used outside a control method"
};


@interface Fix : NSObject


@end
