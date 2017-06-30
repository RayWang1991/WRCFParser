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



@interface WRItemSet : NSObject
@property(nonatomic, strong, readwrite)NSMutableArray <WRItem *> *itemList; // work list / item list
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, WRItem *> *completeSet; // complete set
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, WRItem *> *activeSet; // active/predict set
@property(nonatomic, strong, readwrite)NSMutableDictionary <NSString *, NSMutableArray <WRItem *> *>*askingDict;

@end


@interface WREarleyParser : NSObject
@property (nonatomic, strong, readwrite) NSMutableArray <WRItemSet *> *itemSetList;
@property (nonatomic, strong, readwrite) WRLanguage *language;
@property (nonatomic, strong, readwrite) WRScanner *scanner;
// construct SPPF, TODO
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, WRSPPFNode *> *nodeSet;
@property (nonatomic, strong, readwrite) NSArray <NSMutableDictionary <NSString *, WRItem *> *> *processedSetList;
@property (nonatomic, strong, readwrite) WRSPPFNode *parseForest;
- (void)startParsing;
@end


