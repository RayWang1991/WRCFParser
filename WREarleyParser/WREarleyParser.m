

#import "WREarleyParser.h"

@implementation WRNode

@end


@interface WRItem ()
@property(nonatomic, strong, readwrite)NSString *dotedRule;
@end

@implementation WRItem

- (instancetype)initWithRuleStr:(NSString *)ruleStr
                    dotPosition:(NSInteger)dotPosition
                andItemPosition:(NSInteger)itemPosition{

  if(self = [super initWithRuleStr:ruleStr]){
    _dotPos = dotPosition;
    _itemPos = itemPosition;
  }
  return self;
}

+ (instancetype)itemWithRuleStr:(NSString *)ruleStr
                    dotPosition:(NSInteger)dotPosition
                andItemPosition:(NSInteger)itemPosition{
  WRItem *item = [[WRItem alloc]initWithRuleStr:ruleStr
                                    dotPosition:dotPosition
                                andItemPosition:itemPosition];
  return item;
}

- (instancetype)initWithRule:(WRRule *)rule
                 dotPosition:(NSInteger)dotPosition
             andItemPosition:(NSInteger)itemPosition{
  if(self = [super initWithRule:rule]){
    _dotPos = dotPosition;
    _itemPos = itemPosition;
  }
  return self;
}

+ (instancetype)itemWithRule:(WRRule *)rule
                 dotPosition:(NSInteger)dotPosition
             andItemPosition:(NSInteger)itemPosition{
  return [[WRItem alloc]initWithRule:rule
                         dotPosition:dotPosition
                     andItemPosition:itemPosition];
}

- (instancetype)initWithItem:(WRItem *)item
             andItemPosition:(NSInteger)itemPosition{
  if(self = [super initWithRule:item]){
    _dotPos = item.dotPos;
    _itemPos = itemPosition;
  }
  return self;
}

+ (instancetype)itemWithItem:(WRItem *)item andItemPosition:(NSInteger)position{
  return [[WRItem alloc]initWithItem:item
                     andItemPosition:position];
}

- (NSUInteger)hash{
  return self.dotedRule.hash;
}

- (BOOL)isComplete{
  return self.rightTokens.count <= self.dotPos;
}

- (WRToken *)nextAskingToken{
  if(self.isComplete){
    return nil;
  } else{
    return self.rightTokens[_dotPos];
  }
}

- (NSString *)currentDotedRule{
  NSMutableString *mutStr = [NSMutableString stringWithString:self.leftToken.symbol];
  [mutStr appendString:@"->"];
  for(NSUInteger i = 0; i < self.rightTokens.count; i++){
    if(i == _dotPos){
      [mutStr appendString:@"."];
    }
    [mutStr appendString:self.rightTokens[i].symbol];
  }
  if(self.rightTokens.count == _dotPos){
    [mutStr appendString:@"."];
  }
  return mutStr;
}

- (void)setDotPos:(NSInteger)dotPos{
  _dotPos = dotPos;
  _dotedRule = self.currentDotedRule;
}

- (NSString *)dotedRule{
  if(nil == _dotedRule){
    _dotedRule = self.currentDotedRule;
  }
  return _dotedRule;
}
@end

@implementation WRItemSet

@end

@interface WRScanner ()
@property(nonatomic, strong, readwrite)NSString *inputStr;
@property(nonatomic, strong, readwrite)NSArray <WRToken *>*tokenArray;
@property(nonatomic, assign, readwrite)NSInteger index;
@end

@implementation WRScanner
- (instancetype)initWithInputStr:(NSString *)inputStr{
  if(self = [super init]){
    _inputStr = inputStr;
    _index = 0;
    _tokenArray = nil;
  }
  return self;
}

- (void)reset{
  _index = 0;
}

- (void)setInputStr:(NSString *)inputStr{
  _inputStr = inputStr;
  _index = 0;
  _tokenArray = nil;
}

- (WRToken *)nextToken{
  return [self nextTokenWithIndex:self.index];
}

- (NSArray <WRToken *> *)tokenArray{
  if(nil == _tokenArray){
    NSMutableArray *array = [NSMutableArray array];
    for(NSUInteger i = 0 ; i <= self.inputStr.length; i++){
      [array addObject: [self nextTokenWithIndex:i]];
    }
    _tokenArray = array;
  }
  return _tokenArray;
}

// private
- (WRToken *)nextTokenWithIndex:(NSInteger)index{
  if(index >= self.inputStr.length) {
    return nil;
  } else{
    WRToken *token =
    [WRToken tokenWithSymbol:[self.inputStr substringWithRange:NSMakeRange(index, 1)]];
    return token;
  }
}
@end

@interface WREarlyParser ()

@end

@implementation WREarlyParser

// scanner
// completer use the scanner, too
// if succeed return new item, otherwise nil
- (WRItem *)scanItem:(WRItem *)item withTokon:(WRToken *)token andItemSetPosition:(NSInteger)itemSetPos{
  if([item isComplete]){
    return nil;
  }
  if([item.nextAskingToken.symbol isEqualToString:token.symbol] ){
    WRItem *nextItem = [WRItem itemWithItem:item andItemPosition:itemSetPos];
    nextItem.dotPos = item.dotPos + 1;
    return nextItem;
  } else{
    return nil;
  }
}

// predictor
// return the predict items, nil if nothing to predict
- (NSArray <WRItem *> *)predictItem:(WRItem *)item withItemSetPosition:(NSInteger)pos{
  WRToken *predictingToken = item.nextAskingToken;
  if(nil == predictingToken){
    return nil;
  }
  NSArray <WRRule *> *grammarsForPredict = self.language.grammars[predictingToken.symbol];
  if(nil == grammarsForPredict){
    return nil;
  }
  NSMutableArray *array = [NSMutableArray array];
  for(WRRule *rule in grammarsForPredict){
    [array addObject:[WRItem itemWithRule:rule
                              dotPosition:0
                          andItemPosition:pos]];
  }
  
  // Aycock and Horspool. Pratical Earley Parsing Computer J., 45(6): 620-630, 2002
  if([self.language isTokenNullable:predictingToken]){
    [array addObject:[WRItem itemWithItem:item andItemPosition:item.dotPos + 1]];
  }
  return array;
}

//
- (void)startParsing{
  // initiation
  self.itemSetList = [NSMutableArray array];
  WRItemSet *itemSet0 = [[WRItemSet alloc]init];
  NSMutableArray *workList = [NSMutableArray array];
  for(WRRule *startRule in self.language.grammars[self.language.startSymbol]){
    [workList addObject:[WRItem itemWithRule:startRule
                                 dotPosition:0
                             andItemPosition:0]];
  }
  
  for(NSUInteger i = 0; i< workList.count; i++){
    WRItem *currentItem = workList[i];
    if([currentItem isComplete]){
      if(![itemSet0.completeSet containsObject:currentItem]){
        // scann item in complete position, using completed token
        // if the item has been proceeded, skip it
        [itemSet0.completeSet addObject:currentItem];
        NSInteger completeSetPos = currentItem.itemPos;
        NSMutableArray <WRItem *> *array = [NSMutableArray array];
        for(WRItem *activeItem in self.itemSetList[completeSetPos].activeSet){
          WRItem *scannedItem = [self scanItem:activeItem
                                     withTokon:currentItem.leftToken
                            andItemSetPosition:activeItem.itemPos];
          if(scannedItem){
            [array addObject:scannedItem];
          }
        }
        [workList addObjectsFromArray:array];
      }
    } else{
      if(![itemSet0.activeSet containsObject:currentItem]){
        // predict
        [itemSet0.activeSet addObject:currentItem];
        NSInteger activePos = 0;
        if(
      }
      
    }
  }
  
 
  
}

@end
