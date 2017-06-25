//
//  WRRELanguage.m
//  WREarleyParser
//
//  Created by ray wang on 2017/6/23.
//  Copyright © 2017年 ray wang. All rights reserved.
//

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
