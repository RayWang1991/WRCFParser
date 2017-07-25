/* LR(1) Parser Generator
 * Ref 'Parsing Techniques' Chap 9.6 'Engineering a Compiler' Chap 3.4
 * Author: Ray Wang
 * Date: 2017.7.22
 */

#import "WRLR1Parser.h"

NSString *const kWRLR1ParserErrorDomain = @"erorr.Parser.LR1";

@implementation WRLR1Station

- (instancetype)initWithToken:(NSString *)token {
  if (self = [super init]) {
    _token = token;
    _lookAhead = @"";
  }
  return self;
}

+ (instancetype)stationWthToken:(NSString *)token {
  return [[self alloc] initWithToken:token];
}

- (void)addState:(WRLR1NFAState *)state {
  [self.states addObject:state];
}

- (NSMutableArray <WRLR1NFAState *> *)states {
  if (nil == _states) {
    _states = [NSMutableArray array];
  }
  return _states;
}

+ (NSString *)descriptionForToken:(NSString *)token
                     andLookAhead:(NSString *)lookAhead {
  return [NSString stringWithFormat:@"%@, %@",
                                    token,
                                    lookAhead];
}

- (NSString *)description {
  return [WRLR1Station descriptionForToken:self.token
                              andLookAhead:self.lookAhead];
}

@end

@implementation WRLR1NFAState

- (instancetype)initWithItem:(WRItem *)item {
  if (self = [super init]) {
    _item = [WRItemLA1 itemWithItem:item
                     askingPosition:-1];
    [self refreshSymbol];
  }
  return self;
}

+ (instancetype)NFAStateWithItem:(WRItem *)item {
  return [[self alloc] initWithItem:item];
}

- (void)addTransition:(WRLR1NFATransition *)transition {
  [self.transitions addObject:transition];
}

- (void)setLookAhead:(NSString *)lookAhead {
  [self.item setLookAhead:lookAhead];
  [self refreshSymbol];
}

- (void)refreshSymbol {
  _symbol = self.item.description;
}

- (NSString *)description {
  return self.symbol;
}

- (NSMutableArray <WRLR1NFATransition *> *)transitions {
  if (nil == _transitions) {
    _transitions = [NSMutableArray array];
  }
  return _transitions;
}

@end

@implementation WRLR1NFATransition

- (instancetype)initNFATransitionWithToState:(WRLR1NFAState *)to
                              andConsumption:(NSString *)consumption {
  if (self = [super init]) {
    _to = to;
    _consumption = consumption;
  }
  return self;
}

+ (instancetype)NFATransitionWithToState:(WRLR1NFAState *)to
                          andConsumption:(NSString *)consumption {
  return [[self alloc] initNFATransitionWithToState:to
                                     andConsumption:consumption];
}

@end

@implementation WRLR1DFAState
+ (NSString *)contentStrForNFAStates:(NSSet <WRLR1NFAState *> *)nfaStates {
  NSArray *array = [nfaStates allObjects];
  array = [array sortedArrayUsingComparator:^NSComparisonResult(WRLR1NFAState *state1, WRLR1NFAState *state2) {
    return [state1.symbol compare:state2.symbol];
  }];
  NSMutableString *str = [NSMutableString string];
  for (WRLR1NFAState *state in array) {
    [str appendFormat:@"%@\n",
                      state.symbol];
  }
  return [NSString stringWithString:str];
}

- (instancetype)initWithContentString:(NSString *)contentString {
  if (self = [super init]) {
    _contentStr = contentString;
  }
  return self;
}

+ (instancetype)DFAStateWithContentString:(NSString *)contentString {
  return [[self alloc] initWithContentString:contentString];
}

+ (instancetype)DFAStateWithNFAStates:(NSMutableSet <WRLR1NFAState *> *)nfaStates {
  return [[self alloc] initWithContentString:[self contentStrForNFAStates:nfaStates]];
}

- (NSString *)description {
  return self.contentStr;
}

- (NSMutableDictionary <NSString *, WRLR1DFAState *> *)transitionDict {
  if (nil == _transitionDict) {
    _transitionDict = [NSMutableDictionary dictionary];
  }
  return _transitionDict;
}
@end

@interface WRLR1Parser ()
// NFA
@property (nonatomic, strong, readwrite) WRLR1Station *startStation;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR1Station *> *stationSet;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR1NFAState *> *NFAStateRecordSet;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR1NFATransition *> *NFATransitionRecordSet;
@end

@interface WRLR1Parser ()
// DFA
@property (nonatomic, strong, readwrite) WRLR1DFAState *DFAStartState;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRLR1DFAState *> *DFARecordSet;
@property (nonatomic, strong, readwrite) NSMutableArray <NSError *> *conflicts;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR1DFAState *> *DFAWorkList;
@end

@interface WRLR1Parser ()
// parsing runtime
@property (nonatomic, strong, readwrite) NSMutableArray <WRToken *> *tokenStack;
@property (nonatomic, strong, readwrite) NSMutableArray <WRToken *> *inputStack;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR1DFAState *> *stateStack;
@property (nonatomic, strong, readwrite) NSMutableArray <NSError *> *errors;
@end

@implementation WRLR1Parser
- (void)prepare {
  assert(_language);
  assert(_scanner);

  [self constructNFA];
  [self printAllNFAStatesAndTransitions];
  [self constructDFA];
  assert(self.conflicts.count == 0);
  [self printAllDFAStatesAndTransitions];
}

#pragma mark NFA construction

- (void)constructNFA {
  // language computation
  [self.language computeFirstSets];
  // initiation
  _stationSet = [NSMutableDictionary dictionary];
  _NFAStateRecordSet = [NSMutableDictionary dictionary];
  _NFATransitionRecordSet = [NSMutableDictionary dictionary];
  [self constructBaseStationSet];

  // start from S, eof
  WRLR1Station *S_EOF = [self stationFamilyWithAskingToken:self.language.startSymbol
                                              andLookAhead:WREndOfFileTokenSymbol];
  NSMutableArray <WRLR1Station *> *workList = [NSMutableArray arrayWithObject:S_EOF];

  while (workList.count) {
    WRLR1Station *station = workList.lastObject;
    [workList removeLastObject];

    for (WRLR1NFAState *state in station.states) {
      WRLR1NFAState *currentState = state;
      NSMutableArray *array = [NSMutableArray array];

      while (currentState) {
        [array addObject:currentState];
        currentState = currentState.transitions.firstObject.to;
      }

      [array removeLastObject];

      // for every item A -> a.y , x
      // compute the first(yx)
      // in reverse order, for efficiency

      __block NSMutableSet <NSString *> *firstSet = [NSMutableSet setWithObject:station.lookAhead];
      [array enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:^(WRLR1NFAState *nfaState, NSUInteger index, BOOL *stop) {
                                NSString *askingToken = nfaState.item.nextAskingToken;
                                if (askingToken.tokenTypeForString == WRTokenTypeNonterminal) {
                                  for (NSString *lookAhead in firstSet) {
                                    NSString *askingStateDes = [WRLR1Station descriptionForToken:askingToken
                                                                                    andLookAhead:lookAhead];
                                    WRLR1Station *askingStation = self.stationSet[askingStateDes];
                                    if (nil == askingStation) {
                                      askingStation = [self stationFamilyWithAskingToken:askingToken
                                                                            andLookAhead:lookAhead];
                                      [workList addObject:askingStation];
                                    }
                                    for (WRLR1NFAState *nextNFAState in askingStation.states) {
                                      [nfaState addTransition:[WRLR1NFATransition NFATransitionWithToState:nextNFAState
                                                                                            andConsumption:nil]];
                                    }
                                  }
                                }
                                if (index > 0) {
                                  if ([self.language isTokenNullable:askingToken]) {
                                    [firstSet unionSet:[self.language firstSetForToken:askingToken]];
                                  } else {
                                    firstSet = [NSMutableSet setWithSet:[self.language firstSetForToken:askingToken]];
                                  }
                                }
                              }];
    }
  }
}

- (void)constructBaseStationSet {
  for (NSString *nonterminal in self.language.nonterminalList) {
    WRLR1Station *baseStation = [WRLR1Station stationWthToken:nonterminal];
    [self.stationSet setValue:baseStation
                       forKey:baseStation.description];
    for (WRRule *rule in self.language.grammars[nonterminal]) {
      WRItemLA1 *item = [WRItemLA1 itemWithRule:rule
                                    dotPosition:0
                                 askingPosition:-1];
      WRLR1NFAState *baseState = [WRLR1NFAState NFAStateWithItem:item];
      [baseStation addState:baseState];
      while (!item.isComplete) {
        WRItemLA1 *nextItem = [WRItemLA1 itemWithRule:item
                                          dotPosition:item.dotPos + 1
                                       askingPosition:-1];
        WRLR1NFAState *nextState = [WRLR1NFAState NFAStateWithItem:nextItem];
        [baseState addTransition:[WRLR1NFATransition NFATransitionWithToState:nextState
                                                               andConsumption:item.nextAskingToken]];
        item = nextItem;
        baseState = nextState;
      }
    }
  }
}

- (WRLR1Station *)stationFamilyWithAskingToken:(NSString *)askingToken
                                  andLookAhead:(NSString *)lookAhead {
  NSString *contentStr = [WRLR1Station descriptionForToken:askingToken
                                              andLookAhead:lookAhead];
  if (self.stationSet[contentStr]) {
    return self.stationSet[contentStr];
  }

  WRLR1Station *baseStation = self.stationSet[[WRLR1Station descriptionForToken:askingToken
                                                                   andLookAhead:@""]];
  WRLR1Station *newStation = [WRLR1Station stationWthToken:askingToken];
  newStation.lookAhead = lookAhead;
  [self.stationSet setValue:newStation
                     forKey:contentStr];

  for (WRLR1NFAState *state in baseStation.states) {
    WRLR1NFAState *newState = [WRLR1NFAState NFAStateWithItem:state.item];
    [newState setLookAhead:lookAhead];
    [self.NFAStateRecordSet setValue:newState
                              forKey:newState.description];
    [newStation addState:newState];
    WRLR1NFATransition *transition = state.transitions.firstObject;
    while (transition) {
      WRLR1NFAState *nextState = transition.to;
      WRLR1NFAState *newNextState = [WRLR1NFAState NFAStateWithItem:nextState.item];
      [newNextState setLookAhead:lookAhead];
      [self.NFAStateRecordSet setValue:newNextState
                                forKey:newNextState.description];
      WRLR1NFATransition *newTransition = [WRLR1NFATransition NFATransitionWithToState:newNextState
                                                                        andConsumption:transition.consumption];
      [newState addTransition:newTransition];
      transition = nextState.transitions.firstObject;
      newState = newNextState;
    }
  }
  return newStation;
}

- (void)printAllNFAStatesAndTransitions {
  for (WRLR1Station *station in self.stationSet.allValues) {
    if (station.lookAhead.length == 0) {
      continue;
    }
    for (WRLR1NFAState *state in station.states) {
      WRLR1NFAState *currentState = state;
      while (currentState) {
        printf("%s\n", currentState.description.UTF8String);
        WRLR1NFAState *nextState = nil;
        for (WRLR1NFATransition *transition in currentState.transitions) {
          NSString *consumption;
          if (transition.consumption) {
            consumption = transition.consumption;
            nextState = transition.to;
          } else {
            consumption = @"epsilon";
          }
          printf("  --%s-->%s\n", consumption.UTF8String, transition.to.description.UTF8String);
        }
        currentState = nextState;
      }
    }
  }
}

#pragma mark DFA construction

- (void)constructDFA {
  // initiation
  _conflicts = [NSMutableArray array];

  _DFARecordSet = [NSMutableDictionary dictionary];
  NSString *S_EOF = [WRLR1Station descriptionForToken:self.language.startSymbol
                                         andLookAhead:WREndOfFileTokenSymbol];
  WRLR1Station *startStation = self.stationSet[S_EOF];
  NSMutableSet *startSet = [NSMutableSet set];

  for (WRLR1NFAState *state in startStation.states) {
    [startSet unionSet:[self epsilonClosureForNFAState:state]];
  }

  NSInteger stateId = 0;
  self.DFAStartState =
    [self DFAStateWithNFAStateSet:startSet
                 andContentString:[WRLR1DFAState contentStrForNFAStates:startSet]];
  [self.DFARecordSet setValue:self.DFAStartState
                       forKey:self.DFAStartState.contentStr];

  // work loop
  NSMutableArray <WRLR1DFAState *> *workList = [NSMutableArray arrayWithObject:self.DFAStartState];
  while (workList.count) {
    WRLR1DFAState *todoState = workList.lastObject;
    todoState.stateId = stateId++;
    [workList removeLastObject];
    for (NSString *shiftToken in todoState.transitionDict.allKeys) {
      NSArray <WRLR1NFAState *> *shiftArray = todoState.transitionDict[shiftToken];
      NSSet <WRLR1NFAState *> *nfaSet = [self epsilonClosureForNFAContainer:shiftArray];
      NSString *contentString = [WRLR1DFAState contentStrForNFAStates:nfaSet];
      WRLR1DFAState *dfaState = self.DFARecordSet[contentString];
      if (!dfaState) {
        dfaState = [self DFAStateWithNFAStateSet:nfaSet
                                andContentString:contentString];
        [self.DFARecordSet setValue:dfaState
                             forKey:contentString];
        [workList addObject:dfaState];
      }
      [todoState.transitionDict setValue:dfaState
                                  forKey:shiftToken];
    }
  }
}

- (NSSet <WRLR1NFAState *> *)epsilonClosureForNFAContainer:(id<NSFastEnumeration>)container {
  NSMutableSet *set = nil;
  for (WRLR1NFAState *state in container) {
    if (set) {
      [set unionSet:[self epsilonClosureForNFAState:state]];
    } else {
      set = [self epsilonClosureForNFAState:state];
    }
  }
  return set;
}

- (NSMutableSet <WRLR1NFAState *> *)epsilonClosureForNFAState:(WRLR1NFAState *)state {
  NSMutableSet <WRLR1NFAState *> *set = [NSMutableSet setWithObject:state];
  NSMutableArray *workList = [NSMutableArray arrayWithObject:state];
  while (workList.count) {
    WRLR1NFAState *todoState = workList.lastObject;
    [workList removeLastObject];
    for (WRLR1NFATransition *transition in todoState.transitions) {
      if (transition.consumption == nil) {
        WRLR1NFAState *nextState = transition.to;
        if (![set containsObject:nextState]) {
          [workList addObject:nextState];
        }
        [set addObject:nextState];
      }
    }
  }
  return set;
}

- (WRLR1DFAState *)DFAStateWithNFAStateSet:(NSSet <WRLR1NFAState *> *)set
                          andContentString:(NSString *)contentString {
  WRLR1DFAState *dfaState = [WRLR1DFAState DFAStateWithContentString:contentString];
  BOOL foundShift = NO;
  // dispose the action / goto meaning
  for (WRLR1NFAState *nfaState in set) {
    WRItemLA1 *item = nfaState.item;
    if ([item isComplete]) {
      // indicating a reduce action
      NSString *reduceToken = item.leftToken;
      if (foundShift) {
        NSString *message =
          [self conflictMessageOnType:WRLR1DFAActionConflictShiftReduce
                         withDFAState:dfaState
                           reduction1:self.language.grammars[dfaState.reduceTokenSymbol][dfaState.reduceRuleIndex]
                           reduction2:nil
                                shift:dfaState.transitionDict.allKeys.firstObject];
        NSError *conflict = [NSError errorWithDomain:kWRLR1ParserErrorDomain
                                                code:WRLR1DFAActionConflictShiftReduce
                                            userInfo:@{@"content": message}];
        [self.conflicts addObject:conflict];
        assert(NO);
      } else if (dfaState.reduceTokenSymbol &&
        (![dfaState.reduceTokenSymbol isEqualToString:reduceToken] || dfaState.reduceRuleIndex != item.ruleIndex)) {
        // error
        NSString *message =
          [self conflictMessageOnType:WRLR1DFAActionConflictReduceReduce
                         withDFAState:dfaState
                           reduction1:self.language.grammars[reduceToken][item.ruleIndex]
                           reduction2:self.language.grammars[dfaState.reduceTokenSymbol][dfaState.reduceRuleIndex]
                                shift:nil];
        NSError *conflict = [NSError errorWithDomain:kWRLR1ParserErrorDomain
                                                code:WRLR1DFAActionConflictReduceReduce
                                            userInfo:@{@"content": message}];
        [self.conflicts addObject:conflict];
        assert(NO);
      } else {
        // available reduce on look ahead
        dfaState.reduceTokenSymbol = reduceToken;
        dfaState.reduceRuleIndex = item.ruleIndex;
        [dfaState.transitionDict setValue:@(1)
                                   forKey:item.lookAhead];
      }
    } else {
      foundShift = YES;
      NSString *shiftToken = item.nextAskingToken;
      if (dfaState.reduceTokenSymbol) {
        // error
        NSString *message =
          [self conflictMessageOnType:WRLR1DFAActionConflictShiftReduce
                         withDFAState:dfaState
                           reduction1:self.language.grammars[dfaState.reduceTokenSymbol][dfaState.reduceRuleIndex]
                           reduction2:nil
                                shift:shiftToken];
        NSError *conflict = [NSError errorWithDomain:kWRLR1ParserErrorDomain
                                                code:WRLR1DFAActionConflictShiftReduce
                                            userInfo:@{@"content": message}];
        [self.conflicts addObject:conflict];
        assert(NO);
      } else {
        // available shift on look ahead
        // record it for further processing
        // array is OK, cauz the next item can not be the same
        NSMutableArray *array = dfaState.transitionDict[shiftToken];
        if (!array) {
          array = [NSMutableArray array];
          [dfaState.transitionDict setValue:array
                                     forKey:shiftToken];
        }

        // This is fast, cauz the first transition is always the nonepsilon one
        WRLR1NFATransition *transitionShift = nil;
        for (WRLR1NFATransition *transition in nfaState.transitions) {
          if (transition.consumption) {
            transitionShift = transition;
            break;
          }
        }
        assert([transitionShift.consumption isEqualToString:shiftToken]);
        [array addObject:transitionShift.to];
      }
    }
  }
  return dfaState;
}

- (void)printAllDFAStatesAndTransitions {
  printf("All DFA States and Transitions:\n");
  for (WRLR1DFAState *dfaState in self.DFARecordSet.allValues) {
    NSString *stateStr = [WRUtils debugStrWithTabs:2
                                         forString:dfaState.contentStr];
    printf("state ID: %ld ", (long) dfaState.stateId);
    if (dfaState.reduceTokenSymbol == nil) {
      printf("shift state\n");
      printf("%s", stateStr.UTF8String);
      for (NSString *transitionTokenStr in dfaState.transitionDict) {
        printf("    --\'%s\'--> %ld\n", transitionTokenStr.UTF8String,
               (long) ((WRLR1DFAState *)dfaState.transitionDict[transitionTokenStr]).stateId);
      }
    } else {
      WRRule *reduceRule = self.language.grammars[dfaState.reduceTokenSymbol][dfaState.reduceRuleIndex];
      printf("reduce state, using %s\n", reduceRule.description.UTF8String);
      printf("%s", stateStr.UTF8String);
    }
  }
}

- (NSString *)conflictMessageOnType:(WRLR1DFAActionConflict)type
                       withDFAState:(WRLR1DFAState *)dfaState
                         reduction1:(WRRule *)rule1
                         reduction2:(WRRule *)rule2
                              shift:(NSString *)shift {
  switch (type) {
    case WRLR1DFAActionConflictReduceReduce: {
      return [NSString stringWithFormat:@"A REDUCE/REDUCE conflict is found in DFA state:\n%@ "
                                          "reduction1:%@\n"
                                          "reduction2:%@\n",
                                        dfaState,
                                        rule1,
                                        rule2];
    }
    case WRLR1DFAActionConflictShiftReduce: {
      return [NSString stringWithFormat:@"A SHIFT/REDUCE conflict is found in DFA state:\n%@ "
                                          "shift:%@\n "
                                          "reduce:%@\n",
                                        dfaState,
                                        shift,
                                        rule1];
    }
    default:return @"";
  }
}

@end
