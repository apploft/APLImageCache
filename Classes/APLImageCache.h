//
//  APLImageCache.h
//  Sobooks
//
//  Created by Mathias Köhnke on 09/10/14.
//  Copyright (c) 2014 apploft GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APLImageDownloaderProtocol.h"

// a unique name of the image type e.g. 'userPhoto' etc. (required)
extern NSString * __nonnull const APLImageType;

// the width of the image that should be used for the cache (required)
extern NSString * __nonnull const APLImageWidth;

// the height of the image that should be used for the cache (required)
extern NSString * __nonnull const APLImageHeight;

// the number of images that can be stored before new images will overwrite
// already cached images (optional)
// default is 500
extern NSString * __nonnull const APLImageMaximumCount;

// the bit depth of the images stored, the value type is FICImageFormatStyle
// from <FastImageCache/FICImageCache.h> as NSNumber (optional)
// default is FICImageFormatStyle32BitBGR
extern NSString * __nonnull const APLImageStyle;

typedef void(^APLImageCacheCompletion)(UIImage * _Nullable image);

/**
 *  APLImageCache
 *
 *  A simple wrapper for the FastImageCache.
 */
@interface APLImageCache : NSObject

/**
 *  Initializes the image cache by providing a image downloader class
 *  and specifying the image types that should be cached.
 *
 *  @param downloaderClass a class that conforms to the APLImageDownloaderProtocol
 *                         If 'nil' the default image downloader will be used.
 *
 *  @param imageDescriptions     an array of dictionaries, each providing a description
 *                         of an image type. The properties 'APLImageType',
 *                         'APLImageWidth' and 'APLImageHeight' must be provided.
 *                         'APLImageMaximumCount' is optional.
 */
+ (void)setupWithDownloader:(nullable Class<APLImageDownloaderProtocol>)downloaderClass
               descriptions:(nonnull NSArray *)imageDescriptions;

/**
 *  A helper method that can be used to retrieve a cached image.
 *
 *  @param remoteURL       the remote URL where the image was downloaded
 *  @param type            the type of the image
 *  @param completionBlock will be called with the image
 */
+ (void)cachedImageForURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type completionBlock:(nullable APLImageCacheCompletion)completionBlock;

/**
 *  A helper method that cancels a request made by using 'cachedImageForURL:type:completionblock:'.
 *
 *  @param remoteURL the remote URL where the image was downloaded
 *  @param type      the type of the image
 */
+ (void)cancelCachedImageRequestForURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type;

/**
 *  A helper method that manually adds an image to the image cache.
 *
 *  @param image     the image
 *  @param remoteURL the remote URL where the image was downloaded
 *  @param type      the type of the image
 */
+ (void)setCachedImage:(nonnull UIImage *)image remoteURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type;

/**
 *  Returns whether or not an image exists in the image cache.
 *
 *  @param remoteURL  the remote URL where the image was downloaded
 *  @param type       the type of the image
 *
 *  @return YES if the image exits in the image cache
 */
+ (BOOL)imageExistsForURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type;

/**
 * The content mode to be used for drawing images. Defaults to ScaleToFill.
 */
+ (void)setCacheContentMode:(UIViewContentMode)contentMode;

@end

/**
 *  A category for UIImageView providing methods for requesting and cancelling of
 *  cached images.
 */
@interface UIImageView (APLImageCache)

/**
 *  Requests an image from the cache and displays it. If there is no image, it will be downloaded
 *  using the provided 'remoteURL'.
 *
 *  @param remoteURL   the remote URL where the image can be downloaded
 *  @param type        the type of the image
 *  @param placeholder a placeholder image
 *  @param completionHandler  a completion block that will be called when the image has been set or the request failed
 */
- (void)requestImageWithURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type placeholder:(nullable UIImage *)placeholder completion:(nullable APLImageCacheCompletion)completionHandler;

/**
 *  Cancels an image request in progress. If the request has already finished, it does nothing.
 */
- (void)cancelImageRequest;
@end

/**
 *  A category for UIButton providing methods for requesting and cancelling of
 *  cached images.
 */
@interface UIButton (APLImageCache)

/**
 *  Requests an image from the cache and displays it as image for the specified button state.
 *  If there is no image, it will be downloaded using the provided 'remoteURL'.
 *
 *  @param remoteURL   the remote URL where the image can be downloaded
 *  @param type        the type of the image
 *  @param placeholder a placeholder image
 *  @param state       the button control state that uses the specified image
 *  @param completionHandler  a completion block that will be called when the image has been set or the request failed
 */
- (void)requestImageWithURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type placeholder:(nullable UIImage *)placeholder forState:(UIControlState)state completion:(nullable APLImageCacheCompletion)completionHandler;

/**
 *  Cancels an image request in progress. If the request has already finished, it does nothing.
 */
- (void)cancelImageRequest;

/**
 *  Requests an image from the cache and displays it as background image for the specified button state.
 *  If there is no image, it will be downloaded using the provided 'remoteURL'.
 *
 *  @param remoteURL   the remote URL where the image can be downloaded
 *  @param type        the type of the image
 *  @param placeholder a placeholder image
 *  @param state       the button control state that uses the specified image
 *  @param completionHandler  a completion block that will be called when the image has been set or the request failed
 */
- (void)requestBackgroundImageWithURL:(nonnull NSURL *)remoteURL type:(nonnull NSString *)type placeholder:(nullable UIImage *)placeholder forState:(UIControlState)state completion:(nullable APLImageCacheCompletion)completionHandler;

/**
 *  Cancels a background image request in progress. If the request has already finished, it does nothing.
 */
- (void)cancelBackgroundImageRequest;
@end
