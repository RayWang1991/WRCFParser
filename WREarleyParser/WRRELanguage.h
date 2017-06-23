//
//  WRRELanguage.h
//  WREarleyParser
//
//  Created by ray wang on 2017/6/23.
//  Copyright © 2017年 ray wang. All rights reserved.
//

#import "WRParsingBasicLib.h"

@interface WRRELanguage : WRLanguage

// @override
//- (instancetype)initWithRuleStrings:(NSArray <NSString *>*)rules andStartSymbol:(NSString *)startSymbol;

+ (WRLanguage *)CFGrammar_RE_Basic; // Left Recursive

@end
