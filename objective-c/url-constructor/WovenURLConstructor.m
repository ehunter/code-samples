/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import "WovenURLConstructor.h"
#import "WovenConfig.h"
#import "WovenPhotoSize.h"
#import "WovenPhoto.h"
#import "NSSet+PhotoSizeExtensions.h"
#import "NSString+HMACEncryption.h"
#import "NSData+Base64.h"
#import <MemoryLaneKit/MemoryLaneKit.h>

@implementation WovenURLConstructor

+ (NSString *)pretzelURLForURL:(NSString *)URL atSize:(CGSize)size
{
    if (![URL length]) {
        DDLogWarn(@"Can't generate pretzel url for empty url");
        return URL;
    }

    NSString *token = [[[[WovenClient sharedClient] accountManager] config] pretzelToken];
    NSString *secretString = [[[[WovenClient sharedClient] accountManager] config] pretzelSecret];
    NSString *pretzelURL = [[[[WovenClient sharedClient] accountManager] config] pretzelBaseURL];

    //    The host is img.woventheapp.com, and the URL scheme looks like:
    //    autosize/{w}x{h}/{token}/{signature}/{base64_url}

    //    w and h are the width and height of the image we wish to download.
    //    url is the url of the image we wish to download.
    //    token will be given to us by Gemstone in the config call.
    //    secret will be given to us by Gemstone in the config call.
    //
    //    Encryption:
    //    signature is a SHA1 HMAC. Its key is the secret and its data is token:url. e.g. 0:photoURL
    //    base64_url is just the url, base64-encoded.

    NSString *signature = [[NSString stringWithFormat:@"%@:%@", token, URL] HMAC_SHA1EncryptWithKey:secretString];
    if (!signature) {
        DDLogWarn(@"Invalid pretzel signature data");
        return URL;
    }
    NSData *base64 = [URL dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64_url = [base64 base64EncodedString];
    // Our base64 encoder adds new lines every 64 characters, this strips those out so url encoding isn't necessary.
    base64_url = [base64_url stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];

    NSString *w = [NSString stringWithFormat:@"%i", (NSUInteger)size.width];
    NSString *h = [NSString stringWithFormat:@"%i", (NSUInteger)size.height];

    // autosize/{w}x{h}/{token}/{signature}/{base64_url}
    return [NSString stringWithFormat:@"%@/autosize/orig/%@x%@/%@/%@/%@", pretzelURL, w, h, token, signature, base64_url];
}

#pragma mark - public methods
+ (NSString *)urlForPhoto:(WovenPhoto *)photo atSize:(CGSize)size;
{
    return [self urlFromSizes:[photo sizes] atSize:size allowEnlargement:NO];
}

+ (NSString *)urlFromSizes:(NSSet *)sizes atSize:(CGSize)size allowEnlargement:(BOOL)allowEnlargement
{
    WovenPhotoSize *photoSize = [sizes bestQualityPhotoSizeForBounds:size];

    // Don't size up a small image
    if (!allowEnlargement &&
        [[photoSize width] integerValue] <= size.width && [[photoSize height] integerValue] <= size.height) {
        return [photoSize url];
    }

    return [self pretzelURLForURL:[photoSize url] atSize:size];
}

@end
