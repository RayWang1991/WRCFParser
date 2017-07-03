/* Regular engine use
 * test
 * Author: Ray Wang
 * Date: 2017.7.3
 */

#import "WRRELanguage.h"

@implementation WRRELanguage

+ (WRLanguage *)CFGrammar_RE_Basic{
  return [[super alloc] initWithRuleStrings:@[@"MidOp -> o | a | ",
                                            @"PostOp -> + | *",
                                            @"Chars -> Chars c | c",
                                            @"Ranges -> Ranges c - c | c - c",
                                            @"CharRange -> [ Chars ] | [ Chars Ranges ] | [ Ranges ] | [ Ranges Chars ]",
                                            @"Fragment -> c | CharRange | ( Fragment ) | Fragment PostOp | Fragment MidOp Fragment",
                                            @"S -> Fragment"]
                             andStartSymbol:@"S"];
}
@end
