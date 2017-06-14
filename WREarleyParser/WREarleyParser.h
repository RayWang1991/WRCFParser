/* Basic Earley Parser
 * From 'Parsing Techniques' Chap 7.2
 * Author: Ray Wang
 * Date: 2017.6.7
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasiclib.h"

/* Basic  */

// which is defined in basic lib

/* Parse Tree */

@interface WRNode : NSObject
@property(nonatomic, strong, readwrite) WRToken *token;
@property(nonatomic, assign, readwrite) NSInteger startPos; //inclusive, -1 unknow
@property(nonatomic, assign, readwrite) NSInteger endPos;   //inclusive, -1 unknow
@property(nonatomic, strong, readwrite) NSArray *children;
@end

/* Earley Parser */

// Earley Item
@interface WRItem : WRRule

@property (nonatomic, strong, readonly) NSString * dotedRule;
@property (nonatomic, assign, readwrite) NSInteger dotPos;   // position of dot
@property (nonatomic, assign, readwrite) NSInteger itemPos; // position in item set

/**
 * initialize Methods
 */

// basic init methods
- (instancetype)initWithRuleStr:(NSString *)ruleStr
                    dotPosition:(NSInteger)dotPosition
                andItemPosition:(NSInteger)itemPosition;

+ (instancetype)itemWithRuleStr:(NSString *)ruleStr
                    dotPosition:(NSInteger)dotPosition
                andItemPosition:(NSInteger)itemPosition;

// copy rule and set dot||item position
- (instancetype)initWithRule:(WRRule *)rule
                 dotPosition:(NSInteger)dotPosition
             andItemPosition:(NSInteger)itemPosition;

+ (instancetype)itemWithRule:(WRRule *)rule
                 dotPosition:(NSInteger)dotPosition
             andItemPosition:(NSInteger)itemPosition;

// copy item and set the position of item set
- (instancetype)initWithItem:(WRItem *)item andItemPosition:(NSInteger)position;

+ (instancetype)itemWithItem:(WRItem *)item andItemPosition:(NSInteger)position;

/**
 * Functional Methods
 */

- (BOOL)isComplete;

/* Right Hand Methods*/

// The symbol right after the dot; asking, next symbol 
- (WRToken *)nextAskingToken;

@end

@interface WRItemSet : NSObject
@property(nonatomic, strong, readwrite)NSMutableArray <WRItem *> *itemList; // work list / item list
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, WRItem *> *completeSet; // complete set
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, WRItem *> *activeSet; // active/predict set
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, NSMutableArray <WRItem *> *>*askingDict;

@end


@interface WREarlyParser : NSObject
@property (nonatomic, strong, readwrite) NSMutableArray <WRItemSet *> *itemSetList;
@property (nonatomic, strong, readwrite) WRLanguage *language;
@property (nonatomic, strong, readwrite) WRScanner *scanner;

- (void)startParsing;
@end
