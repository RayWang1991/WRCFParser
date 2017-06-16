/* Basic Earley Parser
 * From 'Parsing Techniques' Chap 4.1
 * Author: Ray Wang
 * Date: 2017.6.14
 */

#import "WRUngerParser.h"

@interface WRUngerParser ()

@end

@implementation WRUngerParser

- (void)startParsing{
  
}

- (void)test{
  
}

// divide the input length for each tokens
// nil represent impossible
- (NSArray <NSNumber *> *)ruleDividerForTokens:(NSArray <WRToken *>*)tokens
                               withTokenLength:(NSUInteger)length{
  return nil;
}
@end
