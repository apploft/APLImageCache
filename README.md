APLImageCache
========

A simple wrapper for the FastImageCache.

* Easy setup
* Provides UIImageView category for requesting and cancelling. 
* Support for custom image downloader classes. 

## Installation
Install via cocoapods by adding this to your Podfile:

	pod "APLImageCache", "~> 0.0.5"

## Usage
**Import header file:**

	#import <APLImageCache/APLImageCache.h>

**Setup:**

An example that caches two types of images (user photos and book covers):

    NSDictionary *coverDescription = @{ APLImageType : @"bookCover", APLImageWidth : @90, APLImageHeight : @135 };
    NSDictionary *photoDescription = @{ APLImageType : @"userPhoto", APLImageWidth : @50, APLImageHeight : @50 };
    [APLImageCache setupWithDownloader:nil descriptions:@[coverDescription, photoDescription]];
	
_The best place for this is the method 'application:didFinishLaunchingWithOptions:' in the AppDelegate._


**Request:**

    [self.imageView requestImageWithURL:book.coverURL type:@"bookCover" placeholder:placeholder];

**Cancel:**

    [self.imageView cancelImageRequest];
