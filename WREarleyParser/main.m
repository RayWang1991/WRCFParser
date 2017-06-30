//
//  main.m
//  WREarleyParser
//
//  Created by ray wang on 2017/6/9.
//  Copyright © 2017年 ray wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WREarleyParser.h"

#import "WRRELanguage.h"

void test();

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSLog(@"Hello, Earley Parsing!");
    
    WRLexer *lexer = [[WRLexer alloc]init];
    [lexer test];
    
    
    WREarleyParser *parser = [[WREarleyParser alloc]init];
    WRScanner *scanner = [[WRScanner alloc]init];
//    scanner.inputStr = @"abbb";
//    WRLanguage *language = [WRLanguage CFGrammar_SPFER_3];
    WRLanguage *language = [WRRELanguage CFGrammar_RE_Basic];
    scanner.inputStr = @"[c-cc]oc";
    parser.language = language;
    parser.scanner = scanner;
    [parser startParsing];
    
  }
    return 0;
}

void testString(){
  NSString *strss = @"S S S";
    NSRange range0 = NSMakeRange(0, 1);
    NSRange range1 = NSMakeRange(2, 1);
    NSRange range2 = NSMakeRange(4, 1);
    NSString *s0 = [strss substringWithRange:range0];
    NSString *s1 = [strss substringWithRange:range1];
    NSString *s2 = [strss substringWithRange:range2];
    assert(s0 == s1 && s1 == s2);

}

void testSPPNode(){
  WRToken * token1 = [WRToken tokenWithSymbol:@"token"];
  WRToken * token2 = [WRToken tokenWithSymbol:@"token"];
  WRItem * item1 = [WRItem itemWithRuleStr:@"S ->a b" dotPosition:0 andItemPosition:3];
  WRItem * item2 = [WRItem itemWithRuleStr:@"S-> a b" dotPosition:0 andItemPosition:3];
  WRSPPFNode * v1 = [WRSPPFNode SPPFNodeWithContent:token1 leftExtent:3 andRightExtent:4];
  WRSPPFNode * v2 = [WRSPPFNode SPPFNodeWithContent:item1 leftExtent:0 andRightExtent:3];
  WRSPPFNode * w1 = [WRSPPFNode SPPFNodeWithContent:token2 leftExtent:3 andRightExtent:4];
  WRSPPFNode * w2 = [WRSPPFNode SPPFNodeWithContent:item2 leftExtent:0 andRightExtent:3];
  WRToken *startToken = [WRToken tokenWithSymbol:@"S"];
  WRSPPFNode *root = [WRSPPFNode SPPFNodeWithContent:startToken leftExtent:0 andRightExtent:4];
  [root.families addObject:@[v1,v2]];
  
  BOOL res1 = [root containsFamilly:@[w1,w2]];
  BOOL res2 = [root containsFamilly:@[w2,w1]];
  BOOL res3 = [root containsFamilly:@[w1]];
  BOOL res4 = [root containsFamilly:@[w1,w1,w2]];
  assert(res1);
  assert(res2);
  assert(!res3);
  assert(!res4);
}

void testSet(){
  WRItem *item1 = [WRItem itemWithRuleStr:@"S -> A B C" dotPosition:0 andItemPosition:0];
  WRItem *item2 = [WRItem itemWithRuleStr:@"S -> A B C" dotPosition:0 andItemPosition:0];
  
  NSMutableDictionary *set = [NSMutableDictionary dictionary];
  [set setValue:item1 forKey:item1.description];
  assert(set[item1.description] != nil);
  assert(set[item2.description] != nil);
  assert(item1 != item2);
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
