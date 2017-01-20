# XMNetworking

A lightweight but powerful network library with simplified and expressive syntax based on AFNetworking.

The prefix `XM` is the abbreviation of our team [Xcode-Men](http://www.jianshu.com/users/d509cc369c78/). [中文文档](https://github.com/kangzubin/XMNetworking/blob/master/README_CN.md)

![Platform](https://img.shields.io/badge/platform-iOS-red.svg) ![Language](https://img.shields.io/badge/language-Objective--C-orange.svg) [![CocoaPods](https://img.shields.io/badge/pod-v1.0.2-blue.svg)](http://cocoadocs.org/docsets/XMNetworking/) [![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![License](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg)](https://github.com/kangzubin/XMNetworking/blob/master/LICENSE)

## Introduction

![XMNetworking](http://img.kangzubin.cn/xmnetworking/XMNetworking.png) 

As shown in the picture above, the XMNetworking is designed with centralization thought, all the XMRequest objects are launched and managed by XMCenter, and you could modify the callback dispatch queue and general information such as server url, header and parameter for all request through XMCenter, as well as provide two custom pre and post processing block, in which you could set default value for request object and deal with model transformation for response data, business error code checking, network cache and so on. Futhermore, in order to switch to other network library easily or implement the underlying logic by ourself in the future, we add a XMEngine layer to insulate the dependence of third party network library like AFNetworking.

## Features

* Simply and easily to use.
* Powerful functions for all network reqeust usage scenarios (Normal/Upload/Download).
* Designed for RESTful Server API, and providing various serialization type.
* Supporting Batch and Chain requests.
* Cancelable for running request and auto retrying for fail request.
* Global configuration for genneral info and custom respnose processing block.
* Network reachability checking and security policy based on AFNetworking.

## Requirements

* iOS 7.0 or later
* Xcode 7.3 or later

## Installation

### CocoaPods

Add the following line to your `Podfile`, and then run `pod install` or `pod update`. 

```bash
pod 'XMNetworking'
```

**NOTE:** The `XMNetworking` has contained `AFNetworking` source code with version `3.1.0`, and you **should NOT** add `pod AFNetworking` to your `Podfile` to avoid conflict.

### Carthage (Supported only iOS 8+)

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate XMNetworking into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "kangzubin/XMNetworking"
```

Run `carthage update --platform ios` to build the framework and drag the built `XMNetworking.framework` into your Xcode project.

**NOTE:** The `XMNetworking.framework` has contained `AFNetworking` source code with version `3.1.0`, and you **should NOT** add `AFNetworking.framework` to your Xcode project to avoid conflict.

### Manually

Download all the files in the `XMNetworking` *subdirectory*, then add the source files to your Xcode project.

## Getting Started

### Import Headers in Your Source Files

* Installed by CocoaPods or Carthage:

```objc
#import <XMNetworking/XMNetworking.h>
```

* Installed Manually:

```objc
#import "XMNetworking.h"
```

### Network Configuration

```objc
[XMCenter setupConfig:^(XMConfig *config) {
    config.generalServer = @"general server address";
    config.generalHeaders = @{@"general-header": @"general header value"};
    config.generalParameters = @{@"general-parameter": @"general parameter value"};
    config.generalUserInfo = nil;
    config.callbackQueue = dispatch_get_main_queue();
    config.engine = [XMEngine sharedEngine];
#ifdef DEBUG
    config.consoleLog = YES;
#endif
}];
```

You could configure the XMCenter througth a `XMConfig` object by invoking `+setupConfig:` method, the prorerties to be configured are as following:

* **generalServer**: The general server address for XMCenter, if XMRequest.server is `nil` and the XMRequest.useGeneralServer is `YES`, this property will be assigned to XMRequest.server.
* **generalParameters**: The general parameters for XMCenter, if XMRequest.useGeneralParameters is `YES` and this property is not empty, it will be appended to XMRequest.parameters.
* **generalHeaders**: The general headers for XMCenter, if XMRequest.useGeneralHeaders is `YES` and this property is not empty, it will be appended to XMRequest.headers.
* **generalUserInfo**: The general user info for XMCenter, if XMRequest.userInfo is `nil` and this property is not `nil`, it will be assigned to XMRequest.userInfo, and the `userInfo` might be used to distinguish requests with same context.
* **callbackQueue**: The dispatch queue for request callback blocks. If `NULL` (default), a private concurrent queue is used.
* **engine**: The global requests engine for current XMCenter object, `[XMEngine sharedEngine]` by default.
* **consoleLog**: Whether to print the request and response info in console or not, `NO` by default.

And you could modify the general headers and parameters for XMCenter by following methods:
```objc
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;
+ (void)setGeneralParameterValue:(nullable NSString *)value forKey:(NSString *)key;
```

### Normal Request

#### GET

```objc
[XMCenter sendRequest:^(XMRequest *request) {
    request.url = @"http://example.com/v1/foo/bar";
    //request.server = @"http://example.com/v1/";
    //request.api = @"foo/bar";
    request.parameters = @{@"param1": @"value1", @"param2": @"value2"};
    request.headers = @{@"User-Agent": @"Custom User Agent"};
    request.httpMethod = kXMHTTPMethodGET;
} onSuccess:^(id responseObject) {
   NSLog(@"onSuccess: %@", responseObject);
} onFailure:^(NSError *error) {
   NSLog(@"onFailure: %@", error);
} onFinished:^(id responseObject, NSError *error) {
   NSLog(@"onFinished");
}];
```

**NOTE1:** The following two usages to set URL for request are both ok, but when the `server`, `api` and `url` are assigned for a request object at the same time, the value of `url` is used, while the `server` and `api` will be ignored.

```objc
request.url = @"http://example.com/v1/foo/bar";
```
```objc
// if request.server is `nil`, the general server address of XMCenter will be used.
request.server = @"http://example.com/v1/";
request.api = @"foo/bar";
```

**NOTE2:** The callback blocks (success/failure/finished/progress) are optional for a request object and there are several methods with different block arguments in XMCenter to send requests. The success/faillure/finished blocks are called on `callbackQueue` of XMCenter, **while the progress block is called on the session queue**, not the `callbackQueue` of XMCenter !!!

#### POST

```objc
[XMCenter sendRequest:^(XMRequest *request) {
    //request.server = @"http://example.com/v1/";
    request.api = @"foo/bar";
    request.parameters = @{@"param1": @"value1", @"param2": @"value2"};
    request.httpMethod = kXMHTTPMethodPOST; // optional, `POST` by default.
    request.requestType = kXMRequestNormal; // optional, `Normal` by default.
} onSuccess:^(id responseObject) {
   NSLog(@"onSuccess: %@", responseObject);
} onFailure:^(NSError *error) {
   NSLog(@"onFailure: %@", error);
}];
```

#### Other HTTP Methods

Requests with other HTTP methods such as `HEAD`, `DELETE`, `PUT`, `PATCH`, ... are also supporting, and the usage is similar to the above, we won't repeat it here。

See the comments on `XMConst`, `XMRequest` and `XMCenter` for more details.

### Upload Request

```objc
// `NSData` form data.
UIImage *image = [UIImage imageNamed:@"testImage"];
NSData *fileData1 = UIImageJPEGRepresentation(image, 1.0);
// `NSURL` form data.
NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Documents/testImage.png"];
NSURL *fileURL2 = [NSURL fileURLWithPath:path isDirectory:NO];

[XMCenter sendRequest:^(XMRequest *request) {
    request.server = @"http://example.com/v1/";
    request.api = @"foo/bar";
    request.requestType = kXMRequestUpload;
    [request addFormDataWithName:@"image[]" fileName:@"temp.jpg" mimeType:@"image/jpeg" fileData:fileData1];
    [request addFormDataWithName:@"image[]" fileURL:fileURL2];
    // see `XMUploadFormData` for more details.
} onProgress:^(NSProgress *progress) {
    // the progress block is running on the session queue.
    if (progress) {
        NSLog(@"onProgress: %f", progress.fractionCompleted);
    }
} onSuccess:^(id responseObject) {
    NSLog(@"onSuccess: %@", responseObject);
} onFailure:^(NSError *error) {
    NSLog(@"onFailure: %@", error);
} onFinished:^(id responseObject, NSError *error) {
    NSLog(@"onFinished");
}];
```

### Download Request

```objc
[XMCenter sendRequest:^(XMRequest *request) {
    request.url = @"http://example.com/v1/testDownFile.zip";
    request.downloadSavePath = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
    request.requestType = kXMRequestDownload;
} onProgress:^(NSProgress *progress) {
    // the progress block is running on the session queue.
    if (progress) {
        NSLog(@"onProgress: %f", progress.fractionCompleted);
    }
} onSuccess:^(id responseObject) {
    NSLog(@"onSuccess: %@", responseObject);
} onFailure:^(NSError *error) {
    NSLog(@"onFailure: %@", error);
}];
```

### Serialization

There are two properties named `requestSerializerType` and `responseSerializerType` in `XMRequest` to set the serialization type for request parameters and response data respectively.

The enumeration `XMRequestSerializerType` and `XMResponseSerializerType` are defined as following:

```objc
typedef NS_ENUM(NSInteger, XMRequestSerializerType) {
    kXMRequestSerializerRAW     = 0, // default
    kXMRequestSerializerJSON    = 1,
    kXMRequestSerializerPlist   = 2,
};
```

```objc
typedef NS_ENUM(NSInteger, XMResponseSerializerType) {
    kXMResponseSerializerRAW    = 0,
    kXMResponseSerializerJSON   = 1, // default
    kXMResponseSerializerPlist  = 2,
    kXMResponseSerializerXML    = 3,
};
```

See also `AFURLRequestSerialization.h` and `AFURLResponseSerialization.h` .

### Pre-process and Post-process Plugin
#### Pre-process Block for Request
You cloud invoke `[XMCenter setRequestProcessBlock:...]` to set pre-process plugin for XMCenter, in which you set default value for all request.

Note that the `requestProcessBlock` is only suitable for Normal/Upload/Download reqeusts, and it is not effective for Batch and Chain requests.

```objc
[XMCenter setRequestProcessBlock:^(XMRequest *request) {
    // custom pre process logic for all requests.
    request.httpMethod = kXMHTTPMethodPOST;
    request.requestSerializerType = kXMRequestSerializerRAW;
    request.responseSerializerType = kXMResponseSerializerRAW;
}];
```

#### Custom Post-processing Block for Response Data
Normally, the success block is called when the network reqeust finished successfully, and the failure block is called when error occurred.

Nonetheless, it's more likely that you might need to validate the response data or business error code agreed upon with server develorers even if the request is successfully finished. 

Now you could invoke the `[XMCenter setResponseProcessBlock:...]` method to set a custom processing block for response data, the block is called before success block, and if the passed in `error` argument is assigned, the failure block will be called instead.

**In this plugin you cloud deal with model transformation for response data, business error code checking, network cache and so on.**

```objc
[XMCenter setResponseProcessBlock:^(XMRequest *request, id responseObject, NSError *__autoreleasing *error) {
    // Do the custom response data processing logic by yourself.
}];
```

### Batch Requests
Send batch requests concurrently, the all reqeusts are independent to each other, and the success block is called until all reqeusts finished, while the failure block is called once error occurred.

```objc
[XMCenter sendBatchRequest:^(XMBatchRequest *batchRequest) {
    XMRequest *request1 = [XMRequest request];
    request1.url = @"server url 1";
    // set other properties for request1
        
    XMRequest *request2 = [XMRequest request];
    request2.url = @"server url 2";
    // set other properties for request2
        
    [batchRequest.requestArray addObject:request1];
    [batchRequest.requestArray addObject:request2];
} onSuccess:^(NSArray *responseObjects) {
    NSLog(@"onSuccess: %@", responseObjects);
} onFailure:^(NSArray *errors) {
    NSLog(@"onFailure: %@", errors);
} onFinished:^(NSArray *responseObjects, NSArray *errors) {
    NSLog(@"onFinished");
}];
```

The `[XMCenter sendBatchRequest:...]` method return a `identifier` for new running `XMBatchRequest` object, and `identifier` might be used to cancel the batch requests by invoking XMCenter's `cancelRequest:` method.

### Chain Requests
Send chain requests one by one, the next reqeust relied on the response result of the previous reqeust, and the success block is called until all reqeusts finished, while the failure block is called once error occurred. The bool value `sendNext` is used to confirm whether to start next reqeust.

```objc
[XMCenter sendChainRequest:^(XMChainRequest *chainRequest) {
    [[[[chainRequest onFirst:^(XMRequest *request) {
        request.url = @"server url 1";
        // set other properties for request
    }] onNext:^(XMRequest *request, id responseObject, BOOL *sendNext) {
        NSDictionary *params = responseObject;
        if (params.count > 0) {
            request.url = @"server url 2";
            request.parameters = params;
        } else {
            *sendNext = NO;
        }
    }] onNext:^(XMRequest *request, id responseObject, BOOL *sendNext) {
        request.url = @"server url 3";
        request.parameters = @{@"param1": @"value1", @"param2": @"value2"};
    }] onNext: ...];    
} onSuccess:^(NSArray *responseObjects) {
    NSLog(@"onSuccess: %@", responseObjects);
} onFailure:^(NSArray *errors) {
    NSLog(@"onFailure: %@", errors);
} onFinished:^(NSArray *responseObjects, NSArray *errors) {
    NSLog(@"onFinished");
}];
```
The `[XMCenter sendChainRequest:...]` method return a `identifier` for new running `XMChainRequest` object, and `identifier` might be used to cancel the chain requests by invoking XMCenter's `cancelRequest:` method.

### Cancel the Running Request

When you invoke `[XMCenter sendRequest:...]` to send a network reqeust, the method will return a unique identifier for the new running `XMRequest` object (`nil` for fail), you could save the identifier value, and then cancel the running  request by identifier for your business logic later if need. If a request has already finished, and your still use its identifier to cancel the request, the action will be ignored directly.

```objc
// send a request
NSString identifier = [XMCenter sendRequest:^(XMRequest *request) {
    request.url = @"http://example.com/v1/foo/bar";
    request.api = @"test/index.php";
    request.httpMethod = kXMHTTPMethodGET;
    request.timeoutInterval = 10;
    request.retryCount = 1;
} onFailure:^(NSError *error) {
    NSLog(@"onFailure: %@", error);
}];

// your business code
sleep(2);

// cancel the running request by identifier with cancel block
[XMCenter cancelRequest:identifier onCancel:^(XMRequest *request) {
    NSLog(@"onCancel");
}];
```
**NOTE:** The canceled request object (if exist) will be passed in argument to the cancel block, and the cancel block is called on current thread who invoked the `-cancelRequest:` method, not the `callbackQueue` of XMCenter. 

### Network Reachability
There are two ways to get the network reachability:
```objc
[[XMCenter defaultCenter] isNetworkReachable]; 
// Return a bool value to comfirm whether network is reachable or not.

[[XMEngine sharedEngine] reachabilityStatus]; 
// Return the current network reachablity status, -1 to `Unknown`, 0 to `NotReachable, 1 to `WWAN` and 2 to `WiFi`
```

See also `AFNetworkReachabilityManager` for more details.

### SSL Pinning for HTTPS Request

Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Conveniently, the `AFSecurityPolicy` module could help to evaluate server trust against pinned X.509 certificates and public keys over secure connections.

In XMNetworking, we have integrated `AFSecurityPolicy` module for easy-to-use, now you could invoke the `addSSLPinningURL:` method of XMCenter to add domain name which should do SSL Pinning operation for its HTTPS requests.

```objc
[XMCenter addSSLPinningURL:@"https://example.com/"];
```

Then you only need to drag the .cer format certificate files to your project, it means that the bundle of .cer files should be the same with the bundle of XMNetworking's source code files. Note that if you are using XMNetworking as embedded framework (by Carthage), you need to add pinned certificates through following method:

```objc
// Add SSL Pinning Certificate
NSString *certPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"certificate file name" ofType:@"cer"];
NSData *certData = [NSData dataWithContentsOfFile:certPath];
[XMCenter addSSLPinningCert:certData];
[XMCenter addSSLPinningURL:@"https://example.com/"];
```

See also `AFSecurityPolicy` for more details.

## Documents

See [XMNetworking Documents Link](http://cocoadocs.org/docsets/XMNetworking/).

## Unit Tests
XMNetworking includes a suite of unit tests within the `XMNetworkingDemoTests` subdirectory, see test cases in the Tests Target for details.

## Architecture

The soure code files for XMNetworking is compact and concise, there are only four core files in the library: The `XMConst.h` defines some const enums and blocks, and `XMRequest`, `XMCenter`, `XMEngine` are the declaration and implementation for core Class, the architecture of XMNetworking is as follwing:

![XMNetworking Structure](http://img.kangzubin.cn/xmnetworking/XMNetworking-structure.png)

## To Do List

* Support for resume download.
* Support for network cache.
* Test Supporting for tvOS/watchOS/OS X.
* More powerful response data model transformation.
* Plugin mechanism to extend the XMNetworking.

## Author

* [Zubin Kang](https://kangzubin.cn)

## Collaborators
* [southpeak](https://github.com/southpeak)
* [Xcode-Men Team](http://www.jianshu.com/users/d509cc369c78/)

## License
XMNetworking is released under the MIT license. See [LICENSE](https://github.com/kangzubin/XMNetworking/blob/master/LICENSE) for details.

