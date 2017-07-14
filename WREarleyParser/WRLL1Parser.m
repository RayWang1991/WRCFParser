/* Basic LL(1) Parser Generator
 * Ref 'Parsing Techniques' Chap 8.2 'Engineearing a Compiler' Chap 3.3
 * Author: Ray Wang
 * Date: 2017.7.9
 */

#import "WRLL1Parser.h"

NSString *const kWRLL1ParserErrorDomain = @"erorr.Parser.LL1";

@interface WRLL1Parser ()

// construct time
@property (nonatomic, strong, readwrite) NSMutableArray <NSMutableArray <NSNumber *> *> *predictTable;
@property (nonatomic, strong, readwrite) NSMutableArray <NSError *> *conflicts;

// parse time
@property (nonatomic, strong, readwrite) NSMutableArray <NSString *> *tokenStack;
@property (nonatomic, strong, readwrite) NSMutableArray <NSError *> *errors;

- (void)checkTheConflicts;
@end

@implementation WRLL1Parser
#pragma mark - construct preditction table
- (instancetype)init {
  if (self = [super init]) {
    _conflicts = [NSMutableArray array];
  }
  return self;
}

- (void)prepare {
  [self constructiPredictionTable];
  [self printPredictTable];
}

- (void)constructiPredictionTable {
  //0.0 use 1 look ahead
  [self.language addEofToTerminals];

  //0 label the token


  //1.0 initiate for the prediction table
  NSInteger n = self.language.nonterminals.count;
  NSInteger m = self.language.terminals.count;

  _predictTable = [NSMutableArray arrayWithCapacity:n];

  for (NSInteger i = 0; i < n; i++) {
    [_predictTable addObject:[NSMutableArray arrayWithCapacity:m]];
    for (NSInteger j = 0; j < m; j++) {
      [_predictTable[i] addObject:@(-1)];
    }
  }

  //1.1 construct first sets
  [self.language computeFirstSets];

  //1.2 construct follow sets
  [self.language computeFollowSets];

  //1.3 construct first+ sets
  [self.language computeFirstPlusSets];

  //1.4 fill the prediction table
  for (NSString *nontString in self.language.grammars.allKeys) {
    NSInteger nontId = self.language.token2IdMapper[nontString].integerValue;
    for (WRRule *rule in self.language.grammars[nontString]) {
      NSInteger ruleId = rule.ruleIndex;
      for (NSString *terminalStr in [self.language firstPlusSetForToken:nontString
                                                           andRuleIndex:ruleId]) {
        NSInteger termId = self.language.token2IdMapper[terminalStr].integerValue;
        if (self.predictTable[nontId][termId].integerValue >= 0) {
          // already set a rule index
          WRRule *alreadyRule = self.language.grammars[nontString][self.predictTable[nontId][termId].integerValue];
          NSString *content =
            [NSString stringWithFormat:@"An first+/first+ conflict is found in nonterminal:%@ on terminal:%@ for rules:%@, %@",
                                       nontString,
                                       terminalStr,
                                       alreadyRule,
                                       rule];
          NSError *LL1Conflict = [NSError errorWithDomain:kWRLL1ParserErrorDomain
                                                     code:WRLL1ErrorTypeFirstPlusFirstPlusConflict
                                                 userInfo:@{@"content": content}];
          [self.conflicts addObject:LL1Conflict];
        } else {
          self.predictTable[nontId][termId] = @(ruleId);
        }
      }
    }
  }

  //1.5 check the
  [self checkTheConflicts];
}

#pragma mark debug use
- (void)printPredictTable {
  printf("PredictTable:\n");
  NSInteger n = self.language.nonterminals.count;
  NSInteger m = self.language.terminals.count;


  // print header
  NSInteger maxNontLen = 0;
  for (NSInteger i = 0; i < n; i++) {
    maxNontLen = MAX(maxNontLen, self.language.nonterminalList[i].length);
  }
  NSInteger kMargin = 2;

  // "%+ns" format
  NSString *appendFormat = [NSString stringWithFormat:@"%%+%lds",
                                                      (long) (kMargin + maxNontLen)];

  printf(appendFormat.UTF8String, @" ".UTF8String);

  for (NSInteger j = 0; j < m; j++) {
    NSString *terminal = self.language.terminalList[j];
    printf(appendFormat.UTF8String, terminal.UTF8String);
  }
  printf("\n");

  for (NSInteger i = 0; i < n; i++) {
    NSString *nont = self.language.nonterminalList[i];
    printf(appendFormat.UTF8String, nont.UTF8String);
    for (NSInteger j = 0; j < m; j++) {
      NSInteger transition = self.predictTable[i][j].integerValue;
      NSString *des = transition < 0 ? @"e" : [@(transition) description];
      printf(appendFormat.UTF8String, des.UTF8String);
    }
    printf("\n");
  }
}

- (void)checkTheConflicts {
  //TODO tell user the conflicts information just after built the predict table
  NSLog(@"Build predict table... done.");
  if (self.conflicts.count == 0) {
    NSLog(@"The LL1 predict table has no conflicts.");
    return;
  } else {
    NSLog(@"The LL1 predict table has %lu conflicts.", self.conflicts.count);
    for (NSInteger i = 0; i < self.conflicts.count; i++) {
      NSError *conflict = self.conflicts[i];
      NSString *content = conflict.userInfo[@"content"];
      printf("%ld: %s\n", i, content.UTF8String);
    }
    assert(NO);
  }
}

#pragma mark run the parser
- (void)setInputStr:(NSString *)inputStr {
  [self.scanner setInputStr:inputStr];
}

- (void)startParsing {
  [self.scanner reset];
  [self.scanner startScan];
  [self.scanner scanToEnd];

  _tokenStack = [NSMutableArray arrayWithObjects:WREndOfFileTokenSymbol,
                                                 self.language.startSymbol, nil];
  WRToken *currentInputToken = self.scanner.nextToken;

  // TODO
//  while (true) {
//    if(self.tokenStack.count == 0){
//      // parse done
//      NSLog(@"parse done successfully!");
//    } else{
//      NSString *currentFocus = [self.tokenStack lastObject];
//      [self.tokenStack removeLastObject];
//      if([WRToken typeForString:currentFocus] == nonTerminal){
//        NSInteger i = self.tokenStr2IdMapper[currentFocus].integerValue;
//        NSInteger j = self.tokenStr2IdMapper[currentInputToken.symbol].integerValue;
//        NSInteger nextState = self.predictTable[i][j].integerValue;
//        if(nextState < 0){
//          NSLog(@"parse failed!");
//          [self.errors addObject:[WRLL1Parser errorOnCode:WRLL1ParsingErrorTypeUnsupportedTransition
//                                           withInputToken:currentInputToken
//                                         andExpectedToken:currentFocus]];
//          return;
//        } else{
//          WRRule *usingRule = self.token;
//        }
//      } else{
//        
//      }
//    }
//    NSString *tokenSymbol = currentToken.symbol;
//
//    
//  }
}

+ (NSError *)errorOnCode:(WRLL1ParsingError)type
          withInputToken:(WRTerminal *)inputToken
        andExpectedToken:(NSString *)expectedTokenSymbol {

  NSString *content = @"";
  switch (type) {
    // this case should not happen, caz the eof token
    case WRLL1ParsingErrorTypeRunOutOfToken: {
      content = [NSString stringWithFormat:@"run out of token on expecting: %@",
                                           expectedTokenSymbol];
      break;
    }
    case WRLL1ParsingErrorTypeMismatchTokens: {
      content = [NSString stringWithFormat:@"mismatch tokens on input:%@ and expecting: %@ at line%ld, column%ld",
                                           inputToken.symbol,
                                           expectedTokenSymbol,
                                           inputToken.contentInfo.line,
                                           inputToken.contentInfo.column];
      break;
    }
    case WRLL1ParsingErrorTypeUnsupportedTransition: {
      content =
        [NSString stringWithFormat:@"unsupported transition on input:%@ and current nonterminal: %@ at line%ld, column%ld",
                                   inputToken.symbol,
                                   expectedTokenSymbol,
                                   inputToken.contentInfo.line,
                                   inputToken.contentInfo.column];
      break;
    }
    default: break;
  }
  NSError *error = [NSError errorWithDomain:kWRLL1ParserErrorDomain
                                       code:type
                                   userInfo:@{@"content": content}];
  return error;
}
@end
