/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import "NSString+OrphanProtection.h"

NSString * const kNonBreakingChar = @"\u00A0";

@implementation NSString (OrphanProtection)

- (NSString *)stringByProtectingAgainstOrphans
{
    NSMutableString *newString = [self mutableCopy];

    [self enumerateSubstringsInRange:NSMakeRange(0, [newString length])
                             options:NSStringEnumerationByWords | NSStringEnumerationReverse
                          usingBlock:^(NSString *substring, NSRange subrange, NSRange enclosingRange, BOOL *stop) {
                              if (subrange.location > 0) {
                                  // this assumes that there is only one space between words
                                  [newString replaceCharactersInRange:NSMakeRange(subrange.location-1, 1)
                                                           withString:kNonBreakingChar];
                              }
                              *stop = YES;
                          }];
    return [newString autorelease];
}

@end
