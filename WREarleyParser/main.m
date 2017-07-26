/* Basic Earley Parser
 * From 'Parsing Techniques' Chap 7.2
 * Author: Ray Wang
 * Date: 2017.6.7
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    [WRParsingTest testLR1Parser];
  }
  return 0;
}
