//
//  main.m
//  WREarleyParser
//
//  Created by ray wang on 2017/6/9.
//  Copyright © 2017年 ray wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"

void test();

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    // insert code here...
    NSLog(@"Hello, World!");
    test();
  }
    return 0;
}

void tokenTest(){
  NSString *A = @"A";
  NSString *a = @"a";
  WRToken *tokenA1 = [[WRToken alloc]initWithSymbol:A];
  WRToken *tokenA2 = [WRToken tokenWithSymbol:A];
  WRToken *tokena1 = [[WRToken alloc]initWithSymbol:a];
  WRToken *tokena2 = [WRToken tokenWithSymbol:a];
  
  assert([tokenA1.symbol isEqualToString:A]);
  assert(tokenA1.type == nonTerminal);
  assert([tokenA2.symbol isEqualToString:A]);
  assert(tokenA2.type == nonTerminal);
  assert([tokena1.symbol isEqualToString:a]);
  assert(tokena1.type == terminal);
  assert([tokena2.symbol isEqualToString:a]);
  assert(tokena2.type == terminal);
}

void ruleTest(){
  WRRule *rule1 = [WRRule ruleWithRuleStr:@"S  -> A B C   "];
  assert([rule1.leftToken.symbol isEqualToString:@"S"]);
  NSArray <WRToken *>*rightTokens = rule1.rightTokens;
  assert([rightTokens[0].symbol isEqualToString:@"A"]);
  assert([rightTokens[1].symbol isEqualToString:@"B"]);
  assert([rightTokens[2].symbol isEqualToString:@"C"]);
  
  rule1 = [WRRule ruleWithRuleStr:@"S->   "];
  assert([rule1.leftToken.symbol isEqualToString:@"S"]);
  rightTokens = rule1.rightTokens;
  assert(rightTokens.count == 0);
}

void languageTest(){
  WRLanguage *language = [[WRLanguage alloc] initWithRuleStrings: @[@"S -> A a",
                                                                    @"S ->A B C",
                                                                    @"D -> d",
                                                                    @"E -> S A B",
                                                                    @"A ->a",
                                                                    @"A ->",
                                                                    @"B ->C A",
                                                                    @"B->b",
                                                                    @"C->",
                                                                    @"C->c"]
                                                  andStartSymbol:@"S"];
  
  WRToken *S = [WRToken tokenWithSymbol:@"S"];
  WRToken *A = [WRToken tokenWithSymbol:@"A"];
  WRToken *B = [WRToken tokenWithSymbol:@"B"];
  WRToken *C = [WRToken tokenWithSymbol:@"C"];
  WRToken *D = [WRToken tokenWithSymbol:@"D"];
  WRToken *E = [WRToken tokenWithSymbol:@"E"];
  WRToken *a = [WRToken tokenWithSymbol:@"a"];
  WRToken *b = [WRToken tokenWithSymbol:@"b"];
  WRToken *c = [WRToken tokenWithSymbol:@"c"];
  WRToken *d = [WRToken tokenWithSymbol:@"d"];
  assert([language isTokenNullable:S]);
  assert([language isTokenNullable:A]);
  assert([language isTokenNullable:B]);
  assert([language isTokenNullable:C]);
  assert(![language isTokenNullable:D]);
  assert([language isTokenNullable:E]);
  assert(![language isTokenNullable:a]);
  assert(![language isTokenNullable:b]);
  assert(![language isTokenNullable:c]);
  assert(![language isTokenNullable:d]);
}

void test(){
  languageTest();
}
