//
//  APLImageCache.m
//  Sobooks
//
//  Created by Mathias Köhnke on 09/10/14.
//  Copyright (c) 2014 apploft GmbH. All rights reserved.
//

#import "APLImageCache.h"
#import <FastImageCache/FICImageCache.h>
#import <FastImageCache/FICUtilities.h>
#import <objc/runtime.h>
#import "APLDefaultImageDownloader.h"

NSString * const APLImageType = @"APLImageTypeName";
NSString * const APLImageWidth = @"APLImageTypeSizeWidth";
NSString * const APLImageHeight = @"APLImageTypeSizeHeight";
NSString * const APLImageMaximumCount = @"APLImageTypeMaximumCount";
NSString * const APLImageStyle = @"APLImageTypeStyle";

static NSUInteger const kAPLDefaultMaxImageCount = 500;
static UIViewContentMode APLImageCacheContentMode;


@interface APLImageCacheEntity : NSObject <FICEntity>
@property (nonatomic) UIViewContentMode contentMode;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *type;
@property (nonatomic) NSURL *remoteURL;
@end

@implementation APLImageCacheEntity

+ (instancetype)entityWithIdentifier:(NSString *)identifier url:(NSURL *)url type:(NSString *)type contentMode:(UIViewContentMode)contentMode {
    APLImageCacheEntity *instance = [APLImageCacheEntity new];
    instance.contentMode = contentMode;
    instance.identifier = identifier;
    instance.type = type;
    instance.remoteURL = url;
    return instance;
}

- (NSString *)UUID {
    CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString(self.identifier);
    NSString *UUID = FICStringWithUUIDBytes(UUIDBytes);
    
    return UUID;
}

- (NSString *)sourceImageUUID {
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    return self.remoteURL;
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef context, CGSize contextSize) {
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        CGContextClearRect(context, contextBounds);

        CGRect rect = CGRectZero;
        switch (self.contentMode) {
            case UIViewContentModeScaleAspectFit:
                rect = _FICDAspectFitRect(contextSize, image.size);
                break;

            case UIViewContentModeScaleAspectFill:
                rect = _FICDAspectFillRect(contextSize, image.size);
                break;

            default:
                rect = contextBounds;
        }
        
        UIGraphicsPushContext(context);
        [image drawInRect:rect];
        UIGraphicsPopContext();
    };
    
    return drawingBlock;
}

#pragma mark - Image Helper Functions

static CGRect _FICDAspectFitRect(CGSize contextSize, CGSize actualImageSize) {
    CGSize drawImageSize;
    if (actualImageSize.height > actualImageSize.width) {
        drawImageSize.height = contextSize.height;
        drawImageSize.width = actualImageSize.width/actualImageSize.height * contextSize.height;
    }else {
        drawImageSize.width = contextSize.width;
        drawImageSize.height = contextSize.width * actualImageSize.height /  actualImageSize.width;
    }
    return CGRectMake((contextSize.width - drawImageSize.width) / 2, (contextSize.height - drawImageSize.height) / 2, drawImageSize.width, drawImageSize.height);
}

static CGRect _FICDAspectFillRect(CGSize contextSize, CGSize actualImageSize) {
    CGFloat smallerDimension = MIN(actualImageSize.width, actualImageSize.height);
    CGRect cropRect = CGRectMake(0, 0, smallerDimension, smallerDimension);
    
    // Center the crop rect either vertically or horizontally, depending on which dimension is smaller
    if (actualImageSize.width <= actualImageSize.height) {
        cropRect.origin = CGPointMake(0, (CGFloat)rint((actualImageSize.height - smallerDimension) / 2.0f));
    } else {
        cropRect.origin = CGPointMake((CGFloat)rint((actualImageSize.width - smallerDimension) / 2.0f), 0);
    }
    return cropRect;
}

@end



@interface APLImageCache () <FICImageCacheDelegate>
@property (nonatomic, strong) Class<APLImageDownloaderProtocol> imageDownloaderClass;
@property (nonatomic, strong) NSMutableDictionary *operations;
@end

@implementation APLImageCache

+ (instancetype)defaultCache
{
    static APLImageCache *_sharedInstance;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _sharedInstance = [[APLImageCache alloc] init];
        [_sharedInstance setOperations:[NSMutableDictionary dictionary]];
        [[FICImageCache sharedImageCache] setDelegate:_sharedInstance];
    });
    return _sharedInstance;
}

+ (void)setCacheContentMode:(UIViewContentMode)contentMode {
    APLImageCacheContentMode = contentMode;
}

+ (void)setupWithDownloader:(Class<APLImageDownloaderProtocol>)downloaderClass
               descriptions:(NSArray *)imageDescriptions
{
    [APLImageCache defaultCache].imageDownloaderClass = downloaderClass;
    
    if (![imageDescriptions count]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The image description cannot be nil." userInfo:nil];
    }
    
    NSMutableArray *imageFormats = [NSMutableArray array];
    for (NSDictionary* imageDescription in imageDescriptions) {
        [imageFormats addObject:[self formatFromImageDescription:imageDescription]];
    }
    
    [[FICImageCache sharedImageCache] setFormats:imageFormats];
}

+ (FICImageFormat *)formatFromImageDescription:(NSDictionary *)imageDescription
{
    NSString *name = imageDescription[APLImageType];
    NSParameterAssert(name);
    
    NSNumber *width = imageDescription[APLImageWidth];
    NSParameterAssert(width);
    
    NSNumber *height = imageDescription[APLImageHeight];
    NSParameterAssert(height);
    
    NSNumber *maximumCount = imageDescription[APLImageMaximumCount];
    maximumCount = (!maximumCount) ? @(kAPLDefaultMaxImageCount) : maximumCount;
    
    NSNumber *style = imageDescription[APLImageStyle];
    style = (!style) ? @(FICImageFormatStyle32BitBGR) : style;
    
    FICImageFormat *imageFormat = [[FICImageFormat alloc] init];
    imageFormat.name = [APLImageCache formatNameFromImageTypeName:name];
    imageFormat.style = [style unsignedIntegerValue];
    imageFormat.imageSize = CGSizeMake([width floatValue], [height floatValue]);
    imageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    imageFormat.protectionMode = FICImageFormatProtectionModeNone;
    imageFormat.maximumCount = [maximumCount integerValue];
    return imageFormat;
}

+ (void)cachedImageForURL:(NSURL *)remoteURL type:(NSString *)type completionBlock:(void(^)(UIImage*))completionBlock {
    NSString *identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    APLImageCacheEntity *entity = [APLImageCacheEntity entityWithIdentifier:identifier url:remoteURL type:type contentMode:APLImageCacheContentMode];
    [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:type]
                                                           completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
       if (completionBlock) {
           completionBlock(image);
       }
   }];
}

+ (void)cancelCachedImageRequestForURL:(NSURL *)remoteURL type:(NSString *)type {
    NSString *identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    APLImageCacheEntity *entity = [APLImageCacheEntity entityWithIdentifier:identifier url:remoteURL type:type contentMode:APLImageCacheContentMode];
    [[FICImageCache sharedImageCache] cancelImageRetrievalForEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:entity.type]];
}

+ (void)setCachedImage:(UIImage *)image remoteURL:(NSURL *)remoteURL type:(NSString *)type {
    NSString *identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    APLImageCacheEntity *entity = [APLImageCacheEntity entityWithIdentifier:identifier url:remoteURL type:type contentMode:APLImageCacheContentMode];
    [[FICImageCache sharedImageCache] setImage:image forEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:entity.type] completionBlock:nil];
}

+ (BOOL)imageExistsForURL:(NSURL *)remoteURL type:(NSString *)type
{
    APLImageCacheEntity *entity = [APLImageCacheEntity new];
    entity.identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    entity.type = type;
    entity.remoteURL = remoteURL;
    
    return [[FICImageCache sharedImageCache] imageExistsForEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:type]];
}

- (void)addOperation:(id<APLImageDownloaderProtocol>)operation forEntity:(id<FICEntity>)entity
{
    @synchronized(_operations) {
        [_operations setValue:operation forKey:[entity sourceImageUUID]];
    }
}

- (void)removeOperationForEntity:(id<FICEntity>)entity
{
    @synchronized(_operations) {
        [_operations removeObjectForKey:[entity sourceImageUUID]];
    }
}

#pragma mark - FICImageCacheDelegate

- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock
{
    NSURL *requestURL = [entity sourceImageURLWithFormatName:formatName];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    Class downloaderClass = (self.imageDownloaderClass) ? self.imageDownloaderClass : [APLDefaultImageDownloader class];
    id<APLImageDownloaderProtocol> downloader = [[downloaderClass alloc] init];
    [self addOperation:downloader forEntity:entity];
    [downloader startRequest:request completion:^(UIImage *image, NSError *error) {
        [self removeOperationForEntity:entity];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
    }];
}

- (void)imageCache:(FICImageCache *)imageCache cancelImageLoadingForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName
{
    id<APLImageDownloaderProtocol> downloader = [self.operations valueForKey:[entity sourceImageUUID]];
    [downloader cancelRequest];
    [self removeOperationForEntity:entity];
}


#pragma mark - Helper Methods

+ (NSString *)formatNameFromImageTypeName:(NSString *)imageTypeName
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@.%@", bundleIdentifier, imageTypeName];
}


+ (NSString *)identifierForRemoteURL:(NSURL *)url
{
    if ([url isFileURL]) {
        NSString *bundlePath = [[[NSBundle mainBundle] bundleURL] absoluteString];
        return [[url absoluteString] substringFromIndex:[bundlePath length]];
    }
    return [url absoluteString];
}

@end



@implementation UIImageView (APLImageCache)

static char APLImageCacheEntityKey;

- (void)setApl_entity:(APLImageCacheEntity *)entity {
    objc_setAssociatedObject(self, &APLImageCacheEntityKey, entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (APLImageCacheEntity *)apl_entitiy {
    return objc_getAssociatedObject(self, &APLImageCacheEntityKey);;
}

- (void)requestImageWithURL:(NSURL *)remoteURL type:(NSString *)type placeholder:(UIImage *)placeholder completion:(APLImageCacheCompletion)completionHandler
{
    APLImageCacheEntity *entity = [APLImageCacheEntity new];
    entity.identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    entity.type = type;
    entity.remoteURL = remoteURL;
    [self setApl_entity:entity];
    
    FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
        if (image) self.image = image;
        if (completionHandler) completionHandler(image);
    };
    
    NSString *formatName = [APLImageCache formatNameFromImageTypeName:type];
    BOOL imageExists = [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:entity withFormatName:formatName completionBlock:completionBlock];
    
    if (imageExists == NO) {
        self.image = placeholder;
    }
}

- (void)cancelImageRequest
{
    APLImageCacheEntity *entity = [self apl_entitiy];
    [[FICImageCache sharedImageCache] cancelImageRetrievalForEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:entity.type]];
}

@end



@implementation UIButton (APLImageCache)

static char APLImageCacheEntityKey;
static char APLBackgroundImageCacheEntityKey;

- (void)setApl_imageEntity:(APLImageCacheEntity *)entity {
    objc_setAssociatedObject(self, &APLImageCacheEntityKey, entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (APLImageCacheEntity *)apl_imageEntity {
    return objc_getAssociatedObject(self, &APLImageCacheEntityKey);
}

- (void)setApl_backgroundImageEntity:(APLImageCacheEntity *)entity {
    objc_setAssociatedObject(self, &APLBackgroundImageCacheEntityKey, entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (APLImageCacheEntity *)apl_backgroundImageEntity {
    return objc_getAssociatedObject(self, &APLBackgroundImageCacheEntityKey);
}

- (void)requestImageWithURL:(NSURL *)remoteURL type:(NSString *)type placeholder:(UIImage *)placeholder forState:(UIControlState)state completion:(APLImageCacheCompletion)completionHandler
{
    [self requestImageWithURL:remoteURL background:NO type:type placeholder:placeholder forState:state completion:completionHandler];
}

- (void)cancelImageRequest
{
    [self cancelImageRequestForEntitiy:[self apl_imageEntity]];
}

- (void)requestBackgroundImageWithURL:(NSURL *)remoteURL type:(NSString *)type placeholder:(UIImage *)placeholder forState:(UIControlState)state completion:(APLImageCacheCompletion)completionHandler
{
    [self requestImageWithURL:remoteURL background:YES type:type placeholder:placeholder forState:state completion:completionHandler];
}

- (void)cancelBackgroundImageRequest
{
    [self cancelImageRequestForEntitiy:[self apl_backgroundImageEntity]];
}

- (void)requestImageWithURL:(NSURL *)remoteURL background:(BOOL)isBackground type:(NSString *)type placeholder:(UIImage *)placeholder forState:(UIControlState)state completion:(APLImageCacheCompletion)completionHandler
{
    APLImageCacheEntity *entity = [APLImageCacheEntity new];
    entity.identifier = [APLImageCache identifierForRemoteURL:remoteURL];
    entity.type = type;
    entity.remoteURL = remoteURL;
    if (isBackground) {
        [self setApl_backgroundImageEntity:entity];
    } else {
        [self setApl_imageEntity:entity];
    }
    
    FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
        if (image) [self setImage:image forState:state background:isBackground];
        if (completionHandler) completionHandler(image);
    };
    
    NSString *formatName = [APLImageCache formatNameFromImageTypeName:type];
    BOOL imageExists = [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:entity withFormatName:formatName completionBlock:completionBlock];
    
    if (imageExists == NO) {
        [self setImage:placeholder forState:state background:isBackground];
    }
}

- (void)cancelImageRequestForEntitiy:(APLImageCacheEntity*)entity
{
    [[FICImageCache sharedImageCache] cancelImageRetrievalForEntity:entity withFormatName:[APLImageCache formatNameFromImageTypeName:entity.type]];
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state background:(BOOL)isBackground {
    if (isBackground) {
        [self setBackgroundImageWithoutResizing:image forState:state];
    } else {
        [self setImage:image forState:state];
    }
}

- (void)setBackgroundImageWithoutResizing:(UIImage *)image forState:(UIControlState)state {
    CGRect bounds = self.bounds;
    [self setBackgroundImage:image forState:state];
    if (!CGRectEqualToRect(bounds, self.bounds)) {
        self.bounds = bounds;
    }
}

@end
