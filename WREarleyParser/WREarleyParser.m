

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

- (NSString *)description{
  return [NSString stringWithFormat:@"%@ @%ld",self.dotedRule, self.itemPos];
}

- (NSUInteger)hash{
  return self.description.hash;
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
      [mutStr appendString:@"·"];
    }
    [mutStr appendString:self.rightTokens[i].symbol];
  }
  if(self.rightTokens.count == _dotPos){
    [mutStr appendString:@"·"];
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
#pragma mark debug
- (NSString *)description{
  NSMutableString *string = [NSMutableString string];
  // complete set
  [string appendString:@"  completed:\n"];
  for(NSString *item in self.completeSet){
    [string appendString:[NSString stringWithFormat:@"    %@\n",item]];
  }
  
  // active set
  [string appendString:@"  acitive:\n"];
  for(NSString *item in self.activeSet){
    [string appendString:[NSString stringWithFormat:@"    %@\n",item]];
  }
  
  return string;
}

- (NSMutableArray <WRItem *> *)itemList{
  if(nil == _itemList){
    _itemList = [NSMutableArray array];
  }
  return _itemList;
}

- (NSMutableDictionary <NSString *, WRItem *> *)completeSet{
  if(nil == _completeSet){
    _completeSet = [NSMutableDictionary dictionary];
  }
  return _completeSet;
}

- (NSMutableDictionary <NSString *, WRItem *> *)activeSet{
  if(nil == _activeSet){
    _activeSet = [NSMutableDictionary dictionary];
  }
  return _activeSet;
}

- (NSMutableDictionary <NSString *, NSMutableArray <WRItem *> *> *)askingDict{
  if(nil == _askingDict){
    _askingDict = [NSMutableDictionary dictionary];
  }
  return _askingDict;
}
@end

@interface WRScanner ()
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
  return [self nextTokenWithIndex:_index++];
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
  if([item.nextAskingToken matchWith:token] ){
    WRItem *nextItem = [WRItem itemWithRule:item dotPosition:item.dotPos + 1 andItemPosition:itemSetPos];
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
    [array addObject:[WRItem itemWithRule:item
                              dotPosition:item.dotPos + 1
                          andItemPosition:item.itemPos]];
  }
  return array;
}

//
- (void)startParsing{
  // initiation
  self.itemSetList = [NSMutableArray array];
  WRItemSet *itemSet0 = [[WRItemSet alloc]init];
  NSMutableArray <WRItem *>*workList = itemSet0.itemList;
  NSMutableDictionary *workListRecorder = [NSMutableDictionary dictionary];
  for(WRRule *startRule in self.language.grammars[self.language.startSymbol]){
    WRItem *item = [WRItem itemWithRule:startRule
                            dotPosition:0
                        andItemPosition:0];
    [workList addObject:item];
    [workListRecorder setValue:@1
                        forKey:item.description];
  }
  
  for(NSUInteger i = 0; i< workList.count; i++){
    WRItem *currentItem = workList[i];
    if([currentItem isComplete]){
      if(!itemSet0.completeSet[currentItem.description]){
        // scann item in complete position, using completed token
        // if the item has been proceeded, skip it
        [itemSet0.completeSet setValue:currentItem
                                forKey:currentItem.description];
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
        
        // notice, we should only add unproceeded item
        for(WRItem *item in array){
          if(!itemSet0.activeSet[item.description] &&
             !itemSet0.completeSet[item.description] &&
             !workListRecorder[item.description]){
            [workList addObject:item];
            [workListRecorder setValue:@1
                                forKey:item.description];
          }
        }
        
      }
    } else{
      if(!itemSet0.activeSet[currentItem.description]){
        // predict
        [itemSet0.activeSet setValue:currentItem
                              forKey:currentItem.description];
        
        NSInteger activePos = 0;
        NSArray <WRItem *> *array = [self predictItem:currentItem
                                  withItemSetPosition:activePos];
        
        // notice, we should only add unproceeded item
        for(WRItem *item in array){
          if(!itemSet0.activeSet[item.description] &&
             !itemSet0.completeSet[item.description] &&
             !workListRecorder[item.description]){
            [workList addObject:item];
            [workListRecorder setValue:@1
                                forKey:item.description];
          }
        }
      }
      
      // asking dict for scanner use
//      NSMutableArray *array = itemSet0.askingDict[currentItem.description];
//      if(!array){
//        array = [NSMutableArray array];
//      }
//      [array addObject:currentItem];
    }
  }
  
  [self.itemSetList addObject:itemSet0];
  // work loop
  WRToken *inputToken;
  while(nil != (inputToken = [self.scanner nextToken])){
    // scan the active set of last item set
    // get work list
    WRItemSet *lastItemSet = [self.itemSetList lastObject];
    WRItemSet *currentItemSet = [[WRItemSet alloc]init];
    [self.itemSetList addObject:currentItemSet];
//    [currentItemSet.itemList addObjectsFromArray:lastItemSet.activeSet.allValues];
    
    NSInteger currentPosition = self.itemSetList.count - 1;
    workList = currentItemSet.itemList;
    // scan items using input token
    
    // TODO asking dict
    for(WRItem *item in lastItemSet.activeSet.allValues){
      WRItem *scannedItem = nil;
      if(nil != (scannedItem = [self scanItem:item
                                    withTokon:inputToken
                           andItemSetPosition:item.itemPos])){
        [workList addObject:scannedItem];
      }
    }
    [workListRecorder removeAllObjects];
    
    // work list loop
    for(NSUInteger i = 0; i < workList.count; i++){
      WRItem *currentItem = workList[i];
      if([currentItem isComplete]){
        // complete item
        if(!currentItemSet.completeSet[currentItem.description]){
          // scann item in complete position, using completed token
          // if the item has been proceeded, skip it
          [currentItemSet.completeSet setValue:currentItem
                                        forKey:currentItem.description];
          NSInteger completeSetPos = currentItem.itemPos;
          NSMutableArray <WRItem *> *array = [NSMutableArray array];
          for(WRItem *activeItem in self.itemSetList[completeSetPos].activeSet.allValues){
            WRItem *scannedItem = [self scanItem:activeItem
                                       withTokon:currentItem.leftToken
                              andItemSetPosition:activeItem.itemPos];
            if(scannedItem){
              [array addObject:scannedItem];
            }
          }
          // notice, we should only add unproceeded item
          for(WRItem *item in array){
            if(!currentItemSet.activeSet[item.description] &&
               !currentItemSet.completeSet[item.description] &&
               !workListRecorder[item.description]){
              [workList addObject:item];
              [workListRecorder setValue:@1
                                  forKey:item.description];
            }
          }
        }
      } else{
        // active item
        if(!currentItemSet.activeSet[currentItem.description]){
          // predict
          [currentItemSet.activeSet setValue:currentItem
                                      forKey:currentItem.description];
          NSArray <WRItem *> *array = [self predictItem:currentItem
                                    withItemSetPosition:currentPosition];
          // notice, we should only add unproceeded item
          for(WRItem *item in array){
            if(!currentItemSet.activeSet[item.description] &&
               !currentItemSet.completeSet[item.description] &&
               !workListRecorder[item.description]){
              [workList addObject:item];
              [workListRecorder setValue:@1
                                  forKey:item.description];
            }
          }
        }
        
//        NSMutableArray *array = currentItemSet.askingDict[currentItem.description];
//        if(!array){
//          array = [NSMutableArray array];
//        }
//        [array addObject:currentItem];
      }
    }
  }
  [self endParsing];
}

- (void)endParsing{
  [self.itemSetList enumerateObjectsUsingBlock:^(WRItemSet * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    printf("%s",[[NSString stringWithFormat:@"Itemset%lu:\n",idx]UTF8String]);
    printf("%s",[[NSString stringWithFormat:@"%@\n",obj]UTF8String]);
  }];
}
@end
