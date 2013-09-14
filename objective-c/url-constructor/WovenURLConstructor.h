/* Copyright 2011 litl, LLC. All Rights Reserved. */
#import <QuartzCore/QuartzCore.h>

@class WovenPhotoSize;
@class WovenPhoto;

/*
 This a utility class for constructing image URL's used throughout the app.
 There are two types of URL's this class creates:
 1. A url from a hosted service (i.e. flickr) based on a set of available sizes the server gives us.
 2. A 'pretzel' URL constructed from one the above URL's. Pretzel is the image
 resizing service we're using on the server. We send the service a custom image URL with a specific
 width and height. Pretzel returns a new image file at the exact size we requested. This class assists
 in the creation of those custom image URL's.
*/

@interface WovenURLConstructor : NSObject

+ (NSString *)urlForPhoto:(WovenPhoto *)photo atSize:(CGSize)size;
+ (NSString *)urlFromSizes:(NSSet *)sizes atSize:(CGSize)size allowEnlargement:(BOOL)allowEnlargement;

@end
