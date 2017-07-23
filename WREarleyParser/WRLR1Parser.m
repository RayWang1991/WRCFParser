/* LR(1) Parser Generator
 * Ref 'Parsing Techniques' Chap 9.6 'Engineering a Compiler' Chap 3.4
 * Author: Ray Wang
 * Date: 2017.7.22
 */

#import "WRLR1Parser.h"
@implementation WRLR1Station

- (instancetype)initWithToken:(NSString *)token {
  if (self = [super init]) {
    _token = token;
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
  return nil;
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

+ (instancetype)DFAStateWithContentString:(NSString *)contentString{
  return [[self alloc] initWithContentString:contentString];
}

+ (instancetype)DFAStateWithNFAStates:(NSMutableSet <WRLR1NFAState *> *)nfaStates {
  return [[self alloc] initWithContentString:[self contentStrForNFAStates:nfaStates]];
}
@end

@implementation WRLR1Parser

@end
