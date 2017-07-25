/* Basic LR(1) Parser Generator
 * Ref 'Parsing Techniques' Chap 9.6 'Engineering a Compiler' Chap 3.4
 * Author: Ray Wang
 * Date: 2017.7.22
 */

#import "WRParsingBasicLib.h"

extern NSString *const kWRLR1ParserErrorDomain;

@class WRLR1NFAState;
@class WRLR1NFATransition;

@interface WRLR1Station : NSObject
@property (nonatomic, strong, readwrite) NSString *token;
@property (nonatomic, strong, readwrite) NSString *lookAhead;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR1NFAState *> *states;

- (instancetype)initWithToken:(NSString *)token;
+ (instancetype)stationWthToken:(NSString *)token;
- (void)addState:(WRLR1NFAState *)state;
+ (NSString *)descriptionForToken:(NSString *)token
                     andLookAhead:(NSString *)lookAhead;
@end

@interface WRLR1NFAState : NSObject
@property (nonatomic, strong, readwrite) WRItemLA1 *item;
@property (nonatomic, strong, readwrite) NSString *symbol;
@property (nonatomic, strong, readwrite) NSMutableArray <WRLR1NFATransition *> *transitions;

- (instancetype)initWithItem:(WRItem *)item; // copy
+ (instancetype)NFAStateWithItem:(WRItem *)item;
- (void)addTransition:(WRLR1NFATransition *)transition;
- (void)setLookAhead:(NSString *)lookAhead;
@end

@interface WRLR1NFATransition : NSObject
@property (nonatomic, strong, readwrite) NSString *consumption;
@property (nonatomic, strong, readwrite) WRLR1NFAState *to;

- (instancetype)initNFATransitionWithToState:(WRLR1NFAState *)to
                              andConsumption:(NSString *)consumption;

+ (instancetype)NFATransitionWithToState:(WRLR1NFAState *)to
                          andConsumption:(NSString *)consumption;
@end

typedef NS_ENUM(NSInteger, WRLR1DFAActionConflict) {
  WRLR1DFAActionConflictShiftReduce,
  WRLR1DFAActionConflictReduceReduce,
};

@interface WRLR1DFAState : NSObject
@property (nonatomic, assign, readwrite) NSInteger stateId;
@property (nonatomic, strong, readwrite) NSString *contentStr;
@property (nonatomic, strong, readwrite) NSString *reduceTokenSymbol; // nil for shift
@property (nonatomic, assign, readwrite) NSInteger reduceRuleIndex;
@property (nonatomic, strong, readwrite) NSMutableDictionary *transitionDict;
// the transition dictionary is a union. when state is a shift state, the transition dict records the available shifts
// when state is a reduction state, it records the available lookAheads.

- (instancetype)initWithContentString:(NSString *)contentString; // use string indicate nfa set
+ (instancetype)DFAStateWithContentString:(NSString *)contentString;
+ (instancetype)DFAStateWithNFAStates:(NSMutableSet <WRLR1NFAState *> *)nfaStates;
// helper methods for DFA construction
+ (NSString *)contentStrForNFAStates:(NSSet <WRLR1NFAState *> *)nfaStates;
@end

@interface WRLR1Parser : NSObject
@property (nonatomic, strong, readwrite) WRLanguage *language;
@property (nonatomic, strong, readwrite) WRWordScanner *scanner;
@property (nonatomic, strong, readwrite) WRToken *parseTree;

- (void)prepare;
- (void)startParsing;
@end
