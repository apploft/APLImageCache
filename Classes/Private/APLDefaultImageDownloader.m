//
//  APLDefaultImageDownloader.m
//  Sobooks
//
//  Created by Mathias Köhnke on 09/10/14.
//  Copyright (c) 2014 apploft GmbH. All rights reserved.
//

#import "APLDefaultImageDownloader.h"

@interface APLDefaultImageDownloader ()
@property (nonatomic, strong) NSURLSessionDataTask *currentTask;
@end

@implementation APLDefaultImageDownloader

+(NSURLSession *)session {
    static NSURLSession *sSharedSession = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sSharedSession = [NSURLSession sessionWithConfiguration:configuration];
    });
    return sSharedSession;
}

- (void)startRequest:(NSURLRequest *)request completion:(APLImageDownloaderCompletion)completion {
    NSParameterAssert(completion);
    self.currentTask = [[APLDefaultImageDownloader session] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image;
        if (error == nil && data != nil) {
            image = [UIImage imageWithData:data];
        }
        completion(image, error);
        [self setCurrentTask:nil];
    }];
    [self.currentTask resume];
}

- (void)cancelRequest {
    [self.currentTask cancel];
}
@end
