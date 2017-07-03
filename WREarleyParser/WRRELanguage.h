/* Regular engine use
 * test
 * Author: Ray Wang
 * Date: 2017.7.3
 */

#import "WRParsingBasicLib.h"

@interface WRRELanguage : WRLanguage

// @override
//- (instancetype)initWithRuleStrings:(NSArray <NSString *>*)rules andStartSymbol:(NSString *)startSymbol;

+ (WRLanguage *)CFGrammar_RE_Basic; // Left Recursive

@end
