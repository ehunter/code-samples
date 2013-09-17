/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "UIFont+CustomSizes.h"

@implementation UIFont (customSizes)

+ (UIFont *)customRegularFontOfSize:(NSUInteger)size
{
    return [UIFont fontWithName:@"Roboto-Regular" size:size];
}

+ (UIFont *)customBoldFontOfSize:(NSUInteger)size
{
    return [UIFont fontWithName:@"Roboto-Bold" size:size];
}

+ (UIFont *)customBoldCondensedFontOfSize:(NSUInteger)size
{
    return [UIFont fontWithName:@"Roboto-BoldCondensed" size:size];
}

+ (UIFont *)customScriptFontOfSize:(NSUInteger)size
{
    return [UIFont fontWithName:@"CalibanStd" size:size];
}

#pragma mark

+ (UIFont *)customHeadlineFont
{
    return [UIFont customBoldCondensedFontOfSize:(IsPad() ? 60 : 37)];
}

+ (UIFont *)customScrollAccessoryFont
{
    return [UIFont customBoldCondensedFontOfSize:16];
}

+ (UIFont *)customHeaderFont
{
    return [UIFont customBoldCondensedFontOfSize:(IsPad() ? 20 : 17)];
}

+ (UIFont *)customBodyFont
{
    return [UIFont customRegularFontOfSize:14];
}

+ (UIFont *)customBodyBoldFont
{
    return [UIFont customBoldFontOfSize:(IsPad() ? 18 : 16)];
}

+ (UIFont *)customLargeFont
{
    return [UIFont customRegularFontOfSize:16];
}

+ (UIFont *)customLargeBoldFont
{
    return [UIFont customBoldCondensedFontOfSize:(IsPad() ? 28 : 22)];
}

+ (UIFont *)customMediumFont
{
    return [UIFont customRegularFontOfSize:(IsPad() ? 18 : 14)];
}

+ (UIFont *)customSmallFont
{
    return [UIFont customRegularFontOfSize:14];
}

+ (UIFont *)customSmallVariableFont
{
     return [UIFont customRegularFontOfSize:(IsPad() ? 14 : 12)];
}

+ (UIFont *)customScriptLarge
{
    return [UIFont customScriptFontOfSize:25];
}

+ (UIFont *)customScriptMedium
{
    return [UIFont customScriptFontOfSize:(IsPad() ? 30 : 25)];
}

+ (UIFont *)customScriptSmall
{
    return [UIFont customScriptFontOfSize:22];
}

@end
