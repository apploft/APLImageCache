//
//  APLImageDownloaderProtocol.h
//  Sobooks
//
//  Created by Mathias Köhnke on 09/10/14.
//  Copyright (c) 2014 apploft GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^APLImageDownloaderCompletion)(UIImage * _Nullable image, NSError * _Nullable error);

/**
 *  APLImageDownloaderProtocol
 *
 *  A protocol that must be implemented for a custom image downloader class.
 */
@protocol APLImageDownloaderProtocol <NSObject>

/**
 *  Starts the image download process.
 *
 *  @param request    the url request pointing to the remote image
 *  @param completion a completion block that will be called if the image has been downloaded
 *                    or the download has failed.
 */
- (void)startRequest:(nonnull NSURLRequest *)request completion:(nullable APLImageDownloaderCompletion)completion;

/**
 *  Cancels an image download. If the download has already finished, it does nothing.
 */
- (void)cancelRequest;
@end
