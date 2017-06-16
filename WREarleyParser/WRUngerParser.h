/* Basic Earley Parser
 * From 'Parsing Techniques' Chap 4.1
 * Author: Ray Wang
 * Date: 2017.6.14
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasiclib.h"

@interface WRUngerParser : NSObject
@property (nonatomic, strong, readwrite) WRLanguage *language;
@property (nonatomic, strong, readwrite) WRScanner *scanner;

- (void)startParsing;
@end
