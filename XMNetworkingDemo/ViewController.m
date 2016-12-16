//
//  ViewController.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "ViewController.h"
#import "XMNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self demoConfigNetwork];
//    [self demoNormalRequest];
//    [self demoUploadRequest];
//    [self demoDownloadRequest];
//    [self demoCancelRequest];
//    [self demoBatchRequest];
//    [self demoChainRequest];
}

- (void)demoConfigNetwork {
    
    [XMCenter setupConfig:^(XMConfig *config) {
        config.generalServer = @"general server address";
        config.generalHeaders = @{@"general-header": @"general header value"};
        config.generalParameters = @{@"general-parameter": @"general parameter value"};
        config.callbackQueue = dispatch_get_main_queue(); // If `NULL` (default), a private concurrent queue is used.
#ifdef DEBUG
        config.consoleLog = YES;
#endif
    }];
    
    [XMCenter setResponseProcessBlock:^(XMRequest *request, id responseObject, NSError *__autoreleasing *error) {
        // Do the custom response data processing logic by yourself
        // You can assign the passed in `error` argument when error occurred, and the failure block will be called instead of success block.
    }];
    
    // SSL Pinning supporting
    //[XMEngine sharedEngine].sessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
}

- (void)demoNormalRequest {
    
    [XMCenter sendRequest:^(XMRequest *request) {
        request.server = @"http://example.com/v1/";
        request.api = @"foo/bar";
        request.parameters = @{@"param1": @"value1", @"param2": @"value2"};
        request.headers = @{@"User-Agent": @"Custom User Agent"};
    } onSuccess:^(id responseObject) {
        NSLog(@"onSuccess: %@", responseObject);
    } onFailure:^(NSError *error) {
        NSLog(@"onFailure: %@", error);
    }];
}

- (void)demoUploadRequest {
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
}

- (void)demoDownloadRequest {

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
}

- (void)demoBatchRequest {
    
    XMBatchRequest *batchRequest = [XMCenter sendBatchRequest:^(XMBatchRequest *batchRequest) {
        XMRequest *request1 = [XMRequest request];
        request1.url = @"server url 1";
        // set other properties for request1
        
        XMRequest *request2 = [XMRequest request];
        request2.url = @"server url 2";
        // set other properties for request2
        
        [batchRequest.requestArray addObject:request1];
        [batchRequest.requestArray addObject:request2];
    } onSuccess:^(NSArray<id> *responseObjects) {
        NSLog(@"onSuccess: %@", responseObjects);
    } onFailure:^(NSArray<id> *errors) {
        NSLog(@"onFailure: %@", errors);
    } onFinished:^(NSArray<id> *responseObjects, NSArray<id> *errors) {
        NSLog(@"onFinished");
    }];
    
    sleep(0.5);
    
    [batchRequest cancelWithBlock:^{
        NSLog(@"On Cancel");
    }];
}

- (void)demoChainRequest {
    
    XMChainRequest *chainRequest = [XMCenter sendChainRequest:^(XMChainRequest *chainRequest) {
        
        [[[chainRequest onFirst:^(XMRequest *request) {
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
        }];
        
    } onSuccess:^(NSArray<id> *responseObjects) {
        NSLog(@"onSuccess: %@", responseObjects);
    } onFailure:^(NSArray<id> *errors) {
        NSLog(@"onFailure: %@", errors);
    } onFinished:^(NSArray<id> *responseObjects, NSArray<id> *errors) {
        NSLog(@"onFinished");
    }];
    
    sleep(0.5);
    
    [chainRequest cancelWithBlock:^{
        NSLog(@"On Cancel");
    }];
}

- (void)demoCancelRequest {
    
    NSUInteger identifier = [XMCenter sendRequest:^(XMRequest *request) {
        request.server = @"http://example.com/v1/";
        request.api = @"foo/bar";
        request.httpMethod = kXMHTTPMethodGET;
        request.timeoutInterval = 10;
        request.retryCount = 1;
    } onFailure:^(NSError *error) {
        NSLog(@"onFailure: %@", error);
    }];
    
    sleep(2);
    
    [XMCenter cancelRequest:identifier onCancel:^(XMRequest *request) {
        NSLog(@"onCancel");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
