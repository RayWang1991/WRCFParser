

#import "WREarleyParser.h"


@implementation WRItemSet
#pragma mark debug
- (NSString *)description {
  NSMutableString *string = [NSMutableString string];
  // complete set
  [string appendString:@"  completed:\n"];
  for (NSString *itemStr in self.completeSet) {
    [string appendString:[NSString stringWithFormat:@"    %@\n",
                                                    itemStr]];
    WRItem *item = self.completeSet[itemStr];
    if ([item descriptionForReductions]) {
      [string appendString:@"      reductions:\n"];
      [string appendString:[NSString stringWithFormat:@"      %@",
                                                      [item descriptionForReductions]]];
    }
    if ([item descriptionForPredecessors]) {
      [string appendString:@"      predecessor:\n"];
      [string appendString:[NSString stringWithFormat:@"      %@",
                                                      [item descriptionForPredecessors]]];
    }
  }

  // active set
  [string appendString:@"  acitive:\n"];
  for (NSString *itemStr in self.activeSet) {
    [string appendString:[NSString stringWithFormat:@"    %@\n",
                                                    itemStr]];
    WRItem *item = self.activeSet[itemStr];
    if ([item descriptionForReductions]) {
      [string appendString:@"      reductions:\n"];
      [string appendString:[NSString stringWithFormat:@"      %@",
                                                      [item descriptionForReductions]]];
    }
    if ([item descriptionForPredecessors]) {
      [string appendString:@"      predecessor:\n"];
      [string appendString:[NSString stringWithFormat:@"      %@",
                                                      [item descriptionForPredecessors]]];
    }
  }

  return string;

  // asking dict
  for (NSString *key in self.askingDict) {
    [string appendString:[NSString stringWithFormat:@"    %@ %@\n",
                                                    key,
                                                    self.askingDict[key]]];
  }
}

- (NSMutableArray <WRItem *> *)itemList {
  if (nil == _itemList) {
    _itemList = [NSMutableArray array];
  }
  return _itemList;
}

- (NSMutableDictionary <NSString *, WRItem *> *)completeSet {
  if (nil == _completeSet) {
    _completeSet = [NSMutableDictionary dictionary];
  }
  return _completeSet;
}

- (NSMutableDictionary <NSString *, WRItem *> *)activeSet {
  if (nil == _activeSet) {
    _activeSet = [NSMutableDictionary dictionary];
  }
  return _activeSet;
}

- (NSMutableDictionary <NSString *, NSMutableArray <WRItem *> *> *)askingDict {
  if (nil == _askingDict) {
    _askingDict = [NSMutableDictionary dictionary];
  }
  return _askingDict;
}
@end

@interface WREarleyParser ()

@end

@implementation WREarleyParser

// scanner
// completer use the scanner, too
// if succeed return new item, otherwise nil
- (WRItem *)scanItem:(WRItem *)item
           withTokon:(WRToken *)token
  andItemSetPosition:(NSInteger)itemSetPos {
  if ([item isComplete]) {
    return nil;
  }
  if ([item.nextAskingToken matchWith:token]) {
    WRItem *nextItem = [WRItem itemWithRule:item
                                dotPosition:item.dotPos + 1
                            andItemPosition:itemSetPos];
    return nextItem;
  } else {
    return nil;
  }
}

// predictor
// return the predict items, nil if nothing to predict
- (NSArray <WRItem *> *)predictItem:(WRItem *)item
                withItemSetPosition:(NSInteger)pos {
  WRToken *predictingToken = item.nextAskingToken;
  if (nil == predictingToken) {
    return nil;
  }
  NSArray <WRRule *> *grammarsForPredict = self.language.grammars[predictingToken.symbol];
  if (nil == grammarsForPredict) {
    return nil;
  }
  NSMutableArray *array = [NSMutableArray array];
  for (WRRule *rule in grammarsForPredict) {
    [array addObject:[WRItem itemWithRule:rule
                              dotPosition:0
                          andItemPosition:pos]];
  }

  // Aycock and Horspool. Pratical Earley Parsing Computer J., 45(6): 620-630, 2002
  if ([self.language isTokenNullable:predictingToken]) {
    [array addObject:[WRItem itemWithRule:item
                              dotPosition:item.dotPos + 1
                          andItemPosition:item.itemPos]];
  }
  return array;
}

// construct the itemsets
- (void)startParsing {
  // initiation
  self.itemSetList = [NSMutableArray array];
  WRItemSet *itemSet0 = [[WRItemSet alloc] init];
  NSMutableArray <WRItem *> *workList = itemSet0.itemList;
  NSMutableDictionary *workListRecorder = [NSMutableDictionary dictionary];
  for (WRRule *startRule in self.language.grammars[self.language.startSymbol]) {
    WRItem *item = [WRItem itemWithRule:startRule
                            dotPosition:0
                        andItemPosition:0];
    [workList addObject:item];
    [workListRecorder setValue:@1 // whatever value here, we only need a set to record the item.description
                        forKey:item.description];
  }

  for (NSUInteger i = 0; i < workList.count; i++) {
    WRItem *currentItem = workList[i];
    if ([currentItem isComplete]) {
      if (!itemSet0.completeSet[currentItem.description]) {
        // scann item in complete position, using completed token
        // if the item has been proceeded, skip it
        [itemSet0.completeSet setValue:currentItem
                                forKey:currentItem.description];
        NSInteger completeSetPos = currentItem.itemPos;
        // can only be itemSet0
        NSMutableArray <WRItem *> *array = [NSMutableArray array];
        for (WRItem *activeItem in itemSet0.askingDict[currentItem.leftToken.symbol]) {
          // +1 is OK
          WRItem *scannedItem = [self scanItem:activeItem
                                     withTokon:currentItem.leftToken
                            andItemSetPosition:activeItem.itemPos];
          if (scannedItem) {
            [array addObject:scannedItem];
          }
        }

        // notice, we should only add unproceeded item
        for (WRItem *item in array) {
          if (!itemSet0.activeSet[item.description] &&
            !itemSet0.completeSet[item.description] &&
            !workListRecorder[item.description]) {
            [workList addObject:item];
            [workListRecorder setValue:@1
                                forKey:item.description];
          }
        }

      }
    } else {
      if (!itemSet0.activeSet[currentItem.description]) {
        // predict
        [itemSet0.activeSet setValue:currentItem
                              forKey:currentItem.description];

        // set asking dict, for scan use
        NSMutableArray *askingArray = itemSet0.askingDict[currentItem.nextAskingToken.symbol];
        if (!askingArray) {
          askingArray = [NSMutableArray arrayWithObject:currentItem];
          [itemSet0.askingDict setValue:askingArray
                                 forKey:currentItem.nextAskingToken.symbol];
        } else {
          [askingArray addObject:currentItem];
        }
        NSInteger activePos = 0;
        NSArray <WRItem *> *array = [self predictItem:currentItem
                                  withItemSetPosition:activePos];

        // notice, we should only add unproceeded item
        for (WRItem *item in array) {
          if (!itemSet0.activeSet[item.description] &&
            !itemSet0.completeSet[item.description] &&
            !workListRecorder[item.description]) {
            [workList addObject:item];
            [workListRecorder setValue:@1
                                forKey:item.description];
          }
        }
      }
    }
  }

  [self.itemSetList addObject:itemSet0];
  // work loop
  WRToken *inputToken;
  while (nil != (inputToken = [self.scanner nextToken])) {
    // scan the active set of last item set
    // get work list
    WRItemSet *lastItemSet = [self.itemSetList lastObject];
    WRItemSet *currentItemSet = [[WRItemSet alloc] init];
    [self.itemSetList addObject:currentItemSet];
//    [currentItemSet.itemList addObjectsFromArray:lastItemSet.activeSet.allValues];

    NSInteger currentPosition = self.itemSetList.count - 1;
    workList = currentItemSet.itemList;
    // scan items using input token

    for (WRItem *item in lastItemSet.askingDict[inputToken.symbol]) {
      // can simply do dotPos + 1
      WRItem *scannedItem = nil;
      if (nil != (scannedItem = [self scanItem:item
                                     withTokon:inputToken
                            andItemSetPosition:item.itemPos])) {
        [workList addObject:scannedItem];
      }
    }
    [workListRecorder removeAllObjects];

    // work list loop
    for (NSUInteger i = 0; i < workList.count; i++) {
      WRItem *currentItem = workList[i];
      if ([currentItem isComplete]) {
        // complete item
        if (!currentItemSet.completeSet[currentItem.description]) {
          // scann item in complete position, using completed token
          // if the item has been proceeded, skip it
          [currentItemSet.completeSet setValue:currentItem
                                        forKey:currentItem.description];
          NSInteger completeSetPos = currentItem.itemPos;
          NSMutableArray <WRItem *> *array = [NSMutableArray array];
          for (WRItem *activeItem in self.itemSetList[completeSetPos].askingDict[currentItem.leftToken.symbol]) {
            // simplely add 1 to dotPos is OK
            WRItem *scannedItem = [self scanItem:activeItem
                                       withTokon:currentItem.leftToken
                              andItemSetPosition:activeItem.itemPos];
            if (scannedItem) {
              [array addObject:scannedItem];
            }
          }
          // notice, we should only add unproceeded item
          for (WRItem *item in array) {
            if (!currentItemSet.activeSet[item.description] &&
              !currentItemSet.completeSet[item.description] &&
              !workListRecorder[item.description]) {
              [workList addObject:item];
              [workListRecorder setValue:@1
                                  forKey:item.description];
            }
          }
        }
      } else {
        // active item
        if (!currentItemSet.activeSet[currentItem.description]) {
          // predict
          [currentItemSet.activeSet setValue:currentItem
                                      forKey:currentItem.description];

          NSMutableArray *askingArray = currentItemSet.askingDict[currentItem.nextAskingToken.symbol];
          if (!askingArray) {
            askingArray = [NSMutableArray arrayWithObject:currentItem];
            [currentItemSet.askingDict setValue:askingArray
                                         forKey:currentItem.nextAskingToken.symbol];
          } else {
            [askingArray addObject:currentItem];
          }

          NSArray <WRItem *> *array = [self predictItem:currentItem
                                    withItemSetPosition:currentPosition];
          // notice, we should only add unproceeded item
          for (WRItem *item in array) {
            if (!currentItemSet.activeSet[item.description] &&
              !currentItemSet.completeSet[item.description] &&
              !workListRecorder[item.description]) {
              [workList addObject:item];
              [workListRecorder setValue:@1
                                  forKey:item.description];
            }
          }
        }
      }
    }
  }
  self.nodeSet = [NSMutableDictionary dictionary];
  NSMutableArray *array = [NSMutableArray array];
  self.processedSetList = array;
  for(NSUInteger i = 0 ;i< self.itemSetList.count; i++){
    [array addObject:[NSMutableDictionary dictionary]];
  }
  [self constructItemPointers];
  [self endParsing];
  // TODO may combine the Item pointer construction with the parsing progress
  [self constructSharedPackedParseForest];
  [self printAST];
}

#pragma mark post construct SPPF
// post construct shared packed parse forest (SPPF)
- (void)constructItemPointers {
  [_scanner reset];
  // dispose item set 0
  WRItemSet *currentSet = self.itemSetList[0];
  for (NSString *completeStr in currentSet.completeSet) {
    WRItem *completeItem = currentSet.completeSet[completeStr];
    WRToken *completeToken = completeItem.leftToken;
    NSUInteger askingItemPos = completeItem.itemPos;
    WRItemSet *askingSet = self.itemSetList[askingItemPos];
    for (WRItem *askingItem in askingSet.askingDict[completeToken.symbol]) {
      WRItem *successorItem = [self successorItemForItem:askingItem
                                               withToken:completeToken
                                      andItemSetPosition:0];
      WRPair *reducPair = [WRPair pairWith:completeItem
                                       and:@(askingItemPos)];
      [successorItem.reductionList setValue:reducPair
                                     forKey:reducPair.description];
      if (askingItem.dotPos != 0) {
        WRPair *predePair = [WRPair pairWith:askingItem
                                         and:@(askingItemPos)];
        [successorItem.predecessorList setValue:predePair
                                         forKey:predePair.description];
      }
    }
  }

  // start from item set 0 (i-1)
  for (NSUInteger i = 0; i < self.itemSetList.count - 1; i++) {
    WRToken *currentToken = _scanner.nextToken;
    WRItemSet *previousSet = self.itemSetList[i];
    WRItemSet *currentSet = self.itemSetList[i + 1];
    assert(currentToken != nil);
    for (WRItem *predecessorItem in previousSet.askingDict[currentToken.symbol]) {
      if (predecessorItem.dotPos != 0) {
        WRItem *successorItem = [self successorItemForItem:predecessorItem
                                                 withToken:currentToken
                                        andItemSetPosition:i + 1];
        WRPair *predePair = [WRPair pairWith:predecessorItem
                                         and:@(i)];
        [successorItem.predecessorList setValue:predePair
                                         forKey:predePair.description];
      }
    }

    for (NSString *completeStr in currentSet.completeSet) {
      WRItem *completeItem = currentSet.completeSet[completeStr];
      WRToken *completeToken = completeItem.leftToken;
      NSUInteger askingItemPos = completeItem.itemPos;
      WRItemSet *askingSet = self.itemSetList[askingItemPos];
      for (WRItem *askingItem in askingSet.askingDict[completeToken.symbol]) {
        WRItem *successorItem = [self successorItemForItem:askingItem
                                                 withToken:completeToken
                                        andItemSetPosition:i + 1];
        WRPair *reducPair = [WRPair pairWith:completeItem
                                         and:@(askingItemPos)];
        [successorItem.reductionList setValue:reducPair
                                       forKey:reducPair.description];
        if (askingItem.dotPos != 0) {
          WRPair *predePair = [WRPair pairWith:askingItem
                                           and:@(askingItemPos)];
          [successorItem.predecessorList setValue:predePair
                                           forKey:predePair.description];
        }
      }
    }
    // check 
  }
}

#pragma mark private constructItemPointer Use
- (WRItem *)successorItemForItem:(WRItem *)item
                       withToken:(WRToken *)token
              andItemSetPosition:(NSUInteger)itemSetPos {
  WRItemSet *set = self.itemSetList[itemSetPos];
  WRItem *nextItem = [self scanItem:item
                          withTokon:token
                 andItemSetPosition:item.itemPos];
  NSString *successorStr = nextItem.description;
  WRItem *successorItem = set.activeSet[successorStr];
  if (nil == successorItem) {
    successorItem = set.completeSet[successorStr];
  }
  assert(successorItem);
  return successorItem;
}

#pragma mark build Shared Packed Parse Forest
- (void)buildTreeWith:(WRSPPFNode *)u
                  and:(WRItem *)item
                inSet:(NSUInteger)i {
  // no nodes for predicated items !!!
  [self.processedSetList[i] setValue:item
                            forKey:item.description];
  if (item.rightTokens.count == 0) {
    // A->·,j form
   WRToken *epsilon = [WRToken tokenWithSymbol:@"epsilon"];
   WRSPPFNode *vChlid = [WRSPPFNode SPPFNodeWithContent:epsilon
                                                leftExtent:i
                                            andRightExtent:i];
    
    if (![u containsFamilly:@[vChlid]]) {
      [u.families addObject:@[vChlid]];
   }
  } else if (item.dotPos == 1 && ((item.justCompletedToken).type == terminal)) {
    // A->a·B,j form
    // a node
    WRSPPFNode *v = [WRSPPFNode SPPFNodeWithContent:item.justCompletedToken
                                         leftExtent:i - 1
                                     andRightExtent:i];
    NSString *vStr = v.description;
    if (self.nodeSet[vStr] == nil) {
      [self.nodeSet setValue:v
                      forKey:vStr];
    } else{
      v = self.nodeSet[vStr];
    }
    if (![u containsFamilly:@[v]]) {
      [u.families addObject:@[v]];
    }
  } else if (item.dotPos == 1 && (item.justCompletedToken).type == nonTerminal) {
    // A->C·B,j form
    // C node
    WRSPPFNode *v = [WRSPPFNode SPPFNodeWithContent:item.justCompletedToken // j
                                         leftExtent:item.itemPos // l
                                     andRightExtent:i];
    NSString *vStr = v.description;
    if (self.nodeSet[vStr] == nil) {
      [self.nodeSet setValue:v
                      forKey:vStr];
    } else{
      v = self.nodeSet[vStr];
    }
    for (WRPair *p in item.reductionList.allValues) {
      NSInteger j = [p.second integerValue];
      if (j == item.itemPos) {
        WRItem *q = p.first;
        if (!self.processedSetList[i][q.description]) {
          [self buildTreeWith:v
                          and:q
                        inSet:i];
        }
      }
    }
    if(![u containsFamilly:@[v]]){
      [u.families addObject:@[v]];
    }
  } else if (item.dotPos > 1 && (item.justCompletedToken).type == terminal) {
    // A->A'a·B,j form
    // a node
    WRSPPFNode *v = [WRSPPFNode SPPFNodeWithContent:item.justCompletedToken
                                         leftExtent:i - 1
                                     andRightExtent:i];
    NSString *vStr = v.description;
    if (self.nodeSet[vStr] == nil) {
      [self.nodeSet setValue:v
                      forKey:vStr];
    } else{
      v = self.nodeSet[vStr];
    }
    // A->A'·aB,j node
    WRItem *preItem = [WRItem itemWithRule:item
                               dotPosition:item.dotPos - 1
                           andItemPosition:item.itemPos];
    preItem = self.itemSetList[i - 1].activeSet[preItem.description];
    WRSPPFNode *w = [WRSPPFNode SPPFNodeWithContent:preItem
                                         leftExtent:preItem.itemPos // j
                                     andRightExtent:i - 1];
    NSString *wStr = w.description;
    if (self.nodeSet[wStr] == nil) {
      [self.nodeSet setValue:w
                      forKey:wStr];
    } else {
      w = self.nodeSet[wStr];
    }

    for (WRPair *p in item.predecessorList.allValues) {
      // there must be 1 and only 1
      assert(item.predecessorList.count == 1);
      NSInteger l = [p.second integerValue];
      WRItem *q = p.first;
      assert(l == i - 1);
      assert(q == preItem);
//      WRSPPFNode *w = [WRSPPFNode SPPFNodeWithContent:q
//                                           leftExtent:q.itemPos // j
//                                       andRightExtent:l];
//      NSString *wStr = w.description;
//      if (self.nodeSet[wStr] == nil) {
//        [self.nodeSet setValue:w
//                        forKey:wStr];
//      } else {
//        w = self.nodeSet[wStr];
//      }
      if (self.processedSetList[l][q.description] == nil) {
        [self buildTreeWith:w
                        and:q
                      inSet:l];
      }
    }
    if (![u containsFamilly:@[w, v]]) {
      [u.families addObject:@[w, v]];
    }
  } else {
    // A->A'C·B,j form
    for (WRPair *p in item.reductionList.allValues) {
      WRItem *redItem = p.first;
      NSInteger l = [p.second integerValue];

      // C node ,l, i
      WRToken *c = item.justCompletedToken;
      WRSPPFNode *v = [WRSPPFNode SPPFNodeWithContent:c
                                           leftExtent:l
                                       andRightExtent:i];
      NSString *vStr = v.description;
      if(self.nodeSet[vStr] == nil){
        [self.nodeSet setValue:v
                        forKey:vStr];
      } else{
        v = self.nodeSet[vStr];
      }
      
      if(self.processedSetList[i][redItem.description] == nil){
        [self buildTreeWith:v
                        and:redItem
                      inSet:i];
      }

      // A->A'·CB @j item j,l
      WRItem *predecessorItem = [WRItem itemWithRule:item
                                         dotPosition:item.dotPos - 1 // asking position for C, l
                                     andItemPosition:item.itemPos]; // asking position for item

      predecessorItem = self.itemSetList[l].activeSet[predecessorItem.description];

      WRSPPFNode *w = [WRSPPFNode SPPFNodeWithContent:predecessorItem
                                           leftExtent:item.itemPos // j
                                       andRightExtent:l];

      NSString *wStr = w.description;
      if (self.nodeSet[wStr] == nil) {
        [self.nodeSet setValue:w
                        forKey:wStr];
      } else{
        w = self.nodeSet[wStr];
      }

      for (WRPair *p in item.predecessorList.allValues) {
        // find the predecessor whose label is l
        NSInteger label = [p.second integerValue];
        WRItem *q = p.first;
        if (label == l) {
          if (self.processedSetList[l][q.description] == nil) {
            [self buildTreeWith:w
                            and:q
                          inSet:l];
          }
        }
      }
      if (![u containsFamilly:@[w, v]]) {
        [u.families addObject:@[w, v]];
      }
    }
  }
}

- (void)constructSharedPackedParseForest {
  WRToken *startToken = [WRToken tokenWithSymbol:self.language.startSymbol];
  NSInteger n = self.itemSetList.count - 1;
  WRSPPFNode *nodeS = [WRSPPFNode SPPFNodeWithContent:startToken
                                           leftExtent:0
                                       andRightExtent:n];
  for (WRItem *item in [self.itemSetList lastObject].completeSet.allValues) {
    if ([item.leftToken.symbol isEqualToString:self.language.startSymbol] && item.itemPos == 0) {
      [self buildTreeWith:nodeS
                      and:item
                    inSet:n];
    }
  }
  if(nodeS.families.count > 0){
    self.parseForest = nodeS;
    NSLog(@"parse forest generated");
  } else{
    NSLog(@"parse failed!");
  }
}


#pragma mark AST Construction
//TODO
- (void)printAST{
  WRSPPFNode *node = [self ambiguousNodeWithNode:self.parseForest];
  BOOL isAmbiguous = node != nil;
  if(isAmbiguous){
    NSLog(@"The result is AMBIGUOUS, with the NODE: %@",node);
    return ;
  }
  NSLog(@"The result is NOT ambiguous");
  // print the whole SPPF
  
  WRTreeNode *rootNode = [self printNodeForNode:self.parseForest];
  [WRTreeNode printTree:rootNode];
}

- (WRTreeNode *)printNodeForNode:(WRSPPFNode *)root{
  if(root == nil){
    return nil;
  }
  
  WRTreeNode *node = [WRTreeNode treeNodeWithContent:root.description];
  assert(root.families.count <= 1);
  if(root.families.count == 0){
    return node;
  }
  
  //TODO
  assert(root.families[0].count > 0);
  assert(root.families[0].count <= 2);
  NSMutableArray *array = [NSMutableArray array];
  node.children = array;
  for(WRSPPFNode *child in root.families[0]){
    WRTreeNode *childNode = [self printNodeForNode:child];
    if(childNode){
      [array addObject:childNode];
    }
  }
  
  return node;
}


// Test if the SPPF is an ambiguous one
- (WRSPPFNode *)ambiguousNodeWithNode:(WRSPPFNode *)node{
  if(node == nil){
    return nil;
  }
  
  if(node.families.count > 1){
    return node;
  }
  WRSPPFNode *res = nil;
  for(NSArray *family in node.families){
    for(WRSPPFNode *child in family){
      res = [self ambiguousNodeWithNode:child];
      if(res){
        return res;
      }
    }
  }
  return nil;
}

- (void)endParsing {
  [self.itemSetList enumerateObjectsUsingBlock:^(WRItemSet *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    printf("%s",
           [[NSString stringWithFormat:@"Itemset%lu:\n",
                                       idx] UTF8String]);
    printf("%s",
           [[NSString stringWithFormat:@"%@\n",
                                       obj] UTF8String]);
  }];
}
@end
