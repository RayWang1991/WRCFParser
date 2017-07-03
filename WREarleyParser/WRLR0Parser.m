/* Basic Earley Parser
 * From 'Parsing Techniques' Chap 7.2
 * Author: Ray Wang
 * Date: 2017.6.30
 */

#import "WRLR0Parser.h"
#pragma mark error for LR0
NSString *const kWRLR0ParserErrorDomain = @"erorr.Parser.WRLR0";

typedef NS_ENUM(NSInteger, WRLR0DFAActionError) {
  WRLR0DFAActionErrorShiftReduceConflict,
  WRLR0DFAActionErrorReduceReduceConflict,
};

#pragma mark NFAState
@interface WRLR0NFAState ()
@end

@implementation WRLR0NFAState

+ (instancetype)NFAStateWithSymbol:(NSString *)symbol
                              type:(WRLR0NFAStateType)type
                        andContent:(id)content; {
  WRLR0NFAState *state = [[WRLR0NFAState alloc] init];
  state.symbol = symbol;
  state.type = type;
  state.content = content;
  return state;
}

+ (instancetype)NFAStateWithContent:(id)content {
  if ([content isKindOfClass:[WRItem class]]) {
    WRItem *item = content;
    return [self NFAStateWithSymbol:item.dotedRule
                               type:WRLR0NFAStateTypeItem
                         andContent:content];
  } else {
    assert([content isKindOfClass:[WRToken class]]);
    WRToken *token = content;
    return [self NFAStateWithSymbol:token.symbol
                               type:WRLR0NFAStateTypeToken
                         andContent:content];
  }
}

- (NSMutableArray <WRLR0NFATransition *> *)transitionList{
  if(nil == _transitionList){
    _transitionList = [NSMutableArray array];
  }
  return _transitionList;
}

- (void)addTransition:(WRLR0NFATransition *)transition {
  [self.transitionList addObject:transition];
}

// override

- (NSString *)description {
  return self.symbol;
}

@end

#pragma mark NFATransition
@implementation WRLR0NFATransition

+ (instancetype)NFATransitionWithFromState:(WRLR0NFAState *)from
                                   toState:(WRLR0NFAState *)to
                            andConsumption:(WRToken *)consumption {
  WRLR0NFATransitionType type = consumption ? WRLR0NFATransitionTypeNormal : WRLR0NFATransitionTypeEpsilon;
  WRLR0NFATransition *transition = [[WRLR0NFATransition alloc] init];
  transition.type = type;
  transition.from = from;
  transition.to = to;
  transition.consumption = consumption;
  return transition;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ --%@--> %@",
                                    _from,
                                    _consumption,
                                    _to];
}
@end

#pragma mark DFAStates
@implementation WRLR0DFAState

- (instancetype)initWithNFAStates:(NSMutableSet<WRLR0NFAState *> *)nfaStates {
  if (self = [super init]) {
    _nfaStates = nfaStates;
    _transitionDict = [NSMutableDictionary dictionaryWithCapacity:16];
  }
  return self;
}

+ (instancetype)DFAStateWithNFAStates:(NSMutableSet < WRLR0NFAState *> *)nfaStates {
  return [[WRLR0DFAState alloc] initWithNFAStates:nfaStates];
}

#pragma mark helper : to speed up the look up
- (NSString *)contentStr {
  // ### important ###
  // must call after the nfa set is determined
  if (nil == _contentStr) {
    _contentStr = [WRLR0DFAState contentStrForNFAStates:self.nfaStates];
  }
  return _contentStr;
}

+ (NSString *)contentStrForNFAStates:(NSSet<WRLR0NFAState *> *)nfaStates {
  NSArray *array = [nfaStates allObjects];
  array = [array sortedArrayUsingComparator:^NSComparisonResult(WRLR0NFAState *state1, WRLR0NFAState *state2) {
    return [state1.symbol compare:state2.symbol];
  }];
  NSMutableString *str = [NSMutableString string];
  for (WRLR0NFAState *state in array) {
    [str appendFormat:@"%@\n",
                      state.symbol];
  }
  return [NSString stringWithString:str];
}

#pragma mark getter
- (NSMutableDictionary<NSString *, WRLR0DFAState *> *)transitionDict {
  if (nil == _transitionDict) {
    _transitionDict = [NSMutableDictionary dictionary];
  }
  return _transitionDict;
}
@end

@interface WRLR0Parser ()
// NFA
@property (nonatomic, strong, readwrite) WRLR0NFAState *NFAStartState;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR0NFAState *> *NFAStateRecordSet;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR0NFATransition *> *NFATransitionRecordSet;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR0NFAState *> *NFAWorkList;
@end

@interface WRLR0Parser ()
//DFA
@property (nonatomic, strong, readwrite) WRLR0DFAState *DFAStartState;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR0DFAState *> *DFARecordSet;
@property (nonatomic, strong, readwrite) NSMutableArray <NSError *> *conflicts;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR0DFAState *> *DFAWorkList;
@end

@implementation WRLR0Parser
- (void)startParsing {
}

- (void)prepare {
  assert(_language);
  assert(_scanner);

  [self constructNFA];
  [self printAllNFAStates];
  [self printAllNFATransitions];
  [self constructDFA];
  assert(self.conflicts.count == 0);
  [self printAllDFAStatesAndTransitions];
}

#pragma mark NFA construction
- (void)constructNFA {
  // initiation
  _NFAStateRecordSet = [NSMutableDictionary dictionary];
  _NFATransitionRecordSet = [NSMutableDictionary dictionary];
  _NFAWorkList = [NSMutableArray array];

  // 1. add Stations 2. add rule 3. map states to stations
  for (NSString *nontStr in self.language.grammars.allKeys) {
    // add station
    WRToken *nontToken = [WRToken tokenWithSymbol:nontStr];
    assert(nontToken.type == nonTerminal);

    WRLR0NFAState *station = _NFAStateRecordSet[nontToken.symbol];
    if(nil == station){
      station = [WRLR0NFAState NFAStateWithContent:nontToken];

      [_NFAStateRecordSet setValue:station
                            forKey:station.symbol];
    }

    for (WRRule *rule in self.language.grammars[nontStr]) {
      // add rule and map states to stations
      [self addRule:rule
          toStation:station];
    }
  }
  _NFAStartState = _NFAStateRecordSet[self.language.startSymbol];
  assert(_NFAStartState);
}

- (void)addRule:(WRRule *)rule
      toStation:(WRLR0NFAState *)station {
  assert(station.type == WRLR0NFAStateTypeToken);
  // add first state to station
  WRItem *item = [WRItem itemWithRule:rule
                          dotPosition:0
                      andItemPosition:-1];
  WRLR0NFAState *state = [WRLR0NFAState NFAStateWithContent:item];
  [_NFAStateRecordSet setValue:state
                        forKey:state.symbol];
  WRLR0NFATransition *transition = [WRLR0NFATransition NFATransitionWithFromState:station
                                                                          toState:state
                                                                   andConsumption:nil];
  [station addTransition:transition];
  // just debug use
  [_NFATransitionRecordSet setValue:transition
                             forKey:transition.description];

  // increase the chain, and ### by the way ### map the state to station
  WRLR0NFAState *nextState = nil;
  WRItem *nextItem = nil;
  WRToken *consumptionToken = nil;
  while (![item isComplete]) {

    consumptionToken = item.nextAskingToken;

    nextItem = [WRItem itemWithRule:item
                        dotPosition:item.dotPos + 1
                    andItemPosition:-1];

    nextState = [WRLR0NFAState NFAStateWithContent:nextItem];
    [_NFAStateRecordSet setValue:nextState
                          forKey:nextState.symbol];

    transition = [WRLR0NFATransition NFATransitionWithFromState:state
                                                        toState:nextState
                                                 andConsumption:consumptionToken];
    [state addTransition:transition];
    [_NFATransitionRecordSet setValue:transition
                               forKey:transition.description];

    if (consumptionToken.type == nonTerminal) {
      station = _NFAStateRecordSet[consumptionToken.symbol];
      if (nil == station) {
        station = [WRLR0NFAState NFAStateWithContent:consumptionToken];
        [_NFAStateRecordSet setValue:station
                              forKey:consumptionToken.symbol];
      }
      transition = [WRLR0NFATransition NFATransitionWithFromState:state
                                                          toState:station
                                                   andConsumption:nil];
      [state addTransition:transition];
      [_NFATransitionRecordSet setValue:transition
                                 forKey:transition.description];

    }

    item = nextItem;
    state = nextState;
  }
}

- (void)printAllNFAStates {
  printf("All NFA States:\n");
  for (NSString *stateStr in self.NFAStateRecordSet.allKeys) {
    printf("  %s\n", [stateStr UTF8String]);
  }
}

- (void)printAllNFATransitions {
  printf("All NFA Transitions:\n");
  for (NSString *transitionStr in self.NFATransitionRecordSet.allKeys) {
    printf("  %s\n", [transitionStr UTF8String]);
  }
}

#pragma mark DFA construction
static int stateId = 0;
- (void)constructDFA {
  // initiation
  _DFARecordSet = [NSMutableDictionary dictionary];
  _conflicts = [NSMutableArray array];
  _DFAWorkList = [NSMutableArray array];
  stateId = 0;

  // start state
  NSMutableSet <WRLR0NFAState *> *nfaStates = [self epsilonClosureOfNFAState:_NFAStartState];
  _DFAStartState = [self DFAStateWithNFAStates:nfaStates];

  [_DFAWorkList addObject:_DFAStartState];
  // work loop
  while (_DFAWorkList.count) {
    WRLR0DFAState *toDoDFAState = [_DFAWorkList lastObject];
    toDoDFAState.stateId = stateId++;
    [_DFAWorkList removeLastObject];
    [_DFARecordSet setValue:toDoDFAState
                     forKey:toDoDFAState.contentStr];
    NSDictionary <NSString *, NSArray *> *transitionTokenDict =
      [self transitionTokenDictForNFAStates:toDoDFAState.nfaStates];
    for (NSString *tokenSymbol in transitionTokenDict) {
      // compute epsilon closure on a transition token
      NSMutableSet *nextNFASet = [NSMutableSet set];
      for (WRLR0NFATransition *transition in transitionTokenDict[tokenSymbol]) {
        [nextNFASet addObject:transition.to];
      }
      nextNFASet = [self epsilonClosureOfNFAStateSet:nextNFASet];

      // find the next DFA state, and mark a transition(use transition dict here)
      NSString *nfaContentStr = [WRLR0DFAState contentStrForNFAStates:nextNFASet];
      WRLR0DFAState *nextDFAState = self.DFARecordSet[nfaContentStr];

      if (!nextDFAState) {
        nextDFAState = [self DFAStateWithNFAStates:nextNFASet];
        [self.DFARecordSet setValue:nextDFAState
                             forKey:nfaContentStr];
      // add to work list
        [self.DFAWorkList addObject:nextDFAState];
      }
      [toDoDFAState.transitionDict setValue:nextDFAState
                                     forKey:tokenSymbol];

    }
  }
}

#pragma mark transition token helper
- (NSMutableDictionary <NSString *, NSMutableArray <WRLR0NFATransition *> *> *)
transitionTokenDictForNFAStates:(NSSet<WRLR0NFAState *> *)nfaStates {
  NSMutableDictionary <NSString *, NSMutableArray *> *dict = [NSMutableDictionary dictionary];
  for (WRLR0NFAState *nfaState in nfaStates) {
    for (WRLR0NFATransition *transition in nfaState.transitionList) {
      if (transition.type == WRLR0NFATransitionTypeNormal) {
        NSString *symbol = transition.consumption.symbol;
        if (nil == dict[symbol]) {
          [dict setValue:[NSMutableArray arrayWithObject:transition]
                  forKey:symbol];
        } else {
          [dict[symbol] addObject:transition];
        }
      }
    }
  }
  return dict;
}

#pragma mark epsilon closure computation
- (NSMutableSet <WRLR0NFAState *> *)epsilonClosureOfNFAState:(WRLR0NFAState *)toDoNFAState {
  NSMutableSet *set = [NSMutableSet setWithObject:toDoNFAState];

  NSInteger lastCount = 0, currentCount = 1;
  while (lastCount < currentCount) {
    lastCount = currentCount;
    for (WRLR0NFAState *nfaState in set.allObjects) {
      for (WRLR0NFATransition *transition in nfaState.transitionList) {
        if (transition.type == WRLR0NFATransitionTypeEpsilon) {
          WRLR0NFAState *toState = transition.to;
          // add is ok, we can make sure that there is only one nfa state for each doted item
          [set addObject:toState];
        }
      }
    }
    currentCount = set.count;
  }
  // remove all station(token content NFA state)
  NSMutableArray *array = [NSMutableArray array];
  for (WRLR0NFAState *state in set) {
    if (state.type == WRLR0NFAStateTypeToken) {
      [array addObject:state];
    }
  }
  for (WRLR0NFAState *state in array) {
    [set removeObject:state];
  }
  return set;
}

- (NSMutableSet <WRLR0DFAState *> *)epsilonClosureOfNFAStateSet:(NSSet <WRLR0NFAState *> *)toDoNFAStateSet {
  NSMutableSet *set = [NSMutableSet set];
  for (WRLR0NFAState *state in toDoNFAStateSet) {
    [set unionSet:[self epsilonClosureOfNFAState:state]];
  }
  return set;
}

#pragma mark DFA state dispose
//#### important , dispose the action/goto here ####
- (WRLR0DFAState *)DFAStateWithNFAStates:(NSMutableSet *)nfaStates {
  assert(nfaStates.count);
  BOOL foundAction = NO;
  WRLR0DFAActionType foundType = WRLR0DFAActionTypeShift;
  NSString *foundReduceSymbol = @"";
  NSInteger foundReduceRuleIndex = 0;
  for (WRLR0NFAState *nfaState in nfaStates) {
    assert([nfaState.content isKindOfClass:[WRItem class]]);
    WRItem *item = nfaState.content;
    if (item.isComplete) {
      WRToken *token = item.leftToken;
      NSString *reduceSymbol = token.symbol;
      if (foundAction) {
        if (foundType != WRLR0DFAActionTypeReduce) {
          NSString *str = [WRLR0DFAState contentStrForNFAStates:nfaStates];
          NSError *error = [NSError errorWithDomain:kWRLR0ParserErrorDomain
                                               code:WRLR0DFAActionErrorShiftReduceConflict
                                           userInfo:@{@"state": str}];
          [self.conflicts addObject:error];
        } else if (![foundReduceSymbol isEqualToString:reduceSymbol] || foundReduceRuleIndex != item.ruleIndex) {
          NSString *str = [WRLR0DFAState contentStrForNFAStates:nfaStates];
          NSError *error = [NSError errorWithDomain:kWRLR0ParserErrorDomain
                                               code:WRLR0DFAActionErrorReduceReduceConflict
                                           userInfo:@{@"state": str}];
          [self.conflicts addObject:error];
        }
      } else {
        foundAction = YES;
        foundType = WRLR0DFAActionTypeReduce;
        foundReduceSymbol = reduceSymbol;
        foundReduceRuleIndex = item.ruleIndex;
      }
    } else {
      if (foundAction) {
        if (foundType != WRLR0DFAActionTypeShift) {
          NSString *str = [WRLR0DFAState contentStrForNFAStates:nfaStates];
          NSError *error = [NSError errorWithDomain:kWRLR0ParserErrorDomain
                                               code:WRLR0DFAActionErrorShiftReduceConflict
                                           userInfo:@{@"state": str}];
          [self.conflicts addObject:error];
        }
        // can not be a shift/shift conflict
      } else {
        foundAction = YES;
        foundType = WRLR0DFAActionTypeShift;
        foundReduceSymbol = @"";
      }
    }
  }
  WRLR0DFAState *dfaState = [WRLR0DFAState DFAStateWithNFAStates:nfaStates];
  assert(foundAction);
  dfaState.actionType = foundType;
  dfaState.reduceTokenSymbol = foundReduceSymbol;
  dfaState.reduceRuleIndex = foundReduceRuleIndex;
  return dfaState;
}

#pragma mark DFA debug
- (void)printAllDFAStatesAndTransitions {
  printf("All DFA States and Transitions:\n");
  for (WRLR0DFAState *dfaState in self.DFARecordSet.allValues) {
    NSString *stateStr = [WRUtils debugStrWithTabs:2 forString:dfaState.contentStr];
    NSString *information = @"";
    printf("state ID: %d ",dfaState.stateId);
    if(dfaState.actionType == WRLR0DFAActionTypeShift){
      printf("shift state\n");
      printf("%s", stateStr.UTF8String);
      for(NSString *transitionTokenStr in dfaState.transitionDict){
        printf("    --\'%s\'--> %d\n", transitionTokenStr.UTF8String, dfaState.transitionDict[transitionTokenStr].stateId);
      }
    } else{
      WRRule *reduceRule = self.language.grammars[dfaState.reduceTokenSymbol][dfaState.reduceRuleIndex];
      printf("reduce state, using %s\n",reduceRule.description.UTF8String);
      printf("%s", stateStr.UTF8String);
    }
  }
}
@end
