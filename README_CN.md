# XMNetworking

XMNetworking 是一个轻量的、简单易用但功能强大的网络库，基于 AFNetworking 3.0 封装。

其中，`XM` 前缀是我们团队 [Xcode-Men](http://www.jianshu.com/users/d509cc369c78/) 的缩写。[英文文档](https://github.com/kangzubin/XMNetworking)

![Platform](https://img.shields.io/badge/platform-iOS-red.svg) ![Language](https://img.shields.io/badge/language-Objective--C-orange.svg) [![CocoaPods](https://img.shields.io/badge/pod-v1.0.2-blue.svg)](http://cocoadocs.org/docsets/XMNetworking/) [![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![License](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg)](https://github.com/kangzubin/XMNetworking/blob/master/LICENSE)

## 简介

![XMNetworking](http://img.kangzubin.cn/xmnetworking/XMNetworking.png) 

如上图所示，XMNetworking 采用中心化的设计思想，由 `XMCenter` 统一发起并管理所有的 `XMRequest` 请求，并可通过 `XMCenter` 给所有请求配置回调线程、公共 Server URL、Header、Parameter 等信息，同时也可以 Block 注入的方式给对所有请求做预处理以及实现自定义的请求响应结果处理逻辑，如数据模型转换、业务错误码判断、网络缓存等。另外增加了 `XMEgine` 这一层是为了隔离底层第三方库依赖，便于以后切换其他底层网络库或自己实现底层逻辑。

## 特性

* 简单易用，发送请求只需调用一个方法，通过 Block 配置信息，代码紧凑；
* 功能强大，适用于几乎所有的网络请求使用场景（普通请求、上传、下载）；
* 专为 RESTful Server API 设计，并提供多种不同的请求和响应的序列化类型；
* 支持批量请求、链式请求等复杂业务逻辑的网络需求;
* 可随时取消未完成的网络请求，支持自动重试失败的请求；
* 全局配置所有请求的公共信息，自定义回调线程以及响应处理逻辑；
* 支持检查网络连接类型，并集成 AFNetworking 强大的安全策略模块。

## 系统要求

* iOS 7.0 以上系统
* Xcode 7.3 或更高版本

## 安装说明

### CocoaPods

在你工程的 `Podfile` 文件中添加如下一行，并执行 `pod install` 或 `pod update`。

```bash
pod 'XMNetworking'
```

**注意：** `XMNetworking` 已经包含了 `AFNetworking` 3.1.0 的源代码，所以你工程里的 `Podfile` 文件**不能**再添加 `pod AFNetworking` 去导入 `AFNetworking`，否则会有冲突！

### Carthage (只支持 iOS 8+)

与 CocoaPods 不同的是，[Carthage](https://github.com/Carthage/Carthage) 是一个去中心化的第三方依赖库管理工具，它自动帮你编译所依赖的第三方库并以 framework 形式提供给你。

你可以通过 [Homebrew](http://brew.sh/) 执行以下命令来安装 Carthage：

```bash
$ brew update
$ brew install carthage
```

成功安装完 Carthage 后，在你工程的 `Cartfile` 文件中添加如下一行：

```ogdl
github "kangzubin/XMNetworking"
```

然后执行 `carthage update --platform ios` 命令生成 framework 包，并把生成的 `XMNetworking.framework` 拖拽到你的工程中。

**注意:** `XMNetworking` 已经包含了 `AFNetworking` 3.1.0 的源代码，所以你**无需**通过 Carthage 生成 `AFNetworking.framework` 导到你工程中，否则会有冲突！

### 手动安装

下载 `XMNetworking` 子文件夹的所有内容，并把其中的源文件添加（拖放）到你的工程中。

## 使用教程

### 头文件的导入

* 如果是通过 CocoaPods 或 Carthage 安装，则:

```objc
#import <XMNetworking/XMNetworking.h>
```

* 如果是手动下载源码安装，则:

```objc
#import "XMNetworking.h"
```

### 全局网络配置

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

你可以调用 `XMCenter` 的 `+setupConfig:` 类方法，通过修改传入的 `XMConfig` 对象来配置全局网络请求的公共信息，包括如下：

* **generalServer**: 公共服务端地址，如果一个 XMRequest 请求对象的 `server` 属性为 `nil`，且其 `useGeneralServer` 为 `YES`（默认），那么该请求的服务端地址 `server` 将会取 XMCenter 中 `generalServer` 的值。
* **generalParameters**: 公共请求参数，如果一个 XMRequest 请求对象的 `useGeneralParameters` 属性为 `YES`（默认），并且 XMCenter 的公共参数 `generalParameters` 不为空，那么这些公共参数会自动加到该请求的 `parameters` 中。
* **generalHeaders**: 公共请求头，如果一个 XMRequest 请求对象的 `useGeneralHeaders` 属性为 `YES`（默认），并且 XMCenter 的公共请求头 `generalHeaders` 不为空，那么这些公共请求头会自动加到该请求的 `headers` 中。
* **generalUserInfo**: 公共用户信息，默认为 `nil`，如果一个 XMRequest 请求对象的 `userInfo` 属性为 `nil`（默认）而该字段不为 `nil`，那么该字段会自动赋值给 `XMRequest` 对象的 `userInfo`。而 `userInfo` 属性可用于区分具有相同上下文信息的不同请求。
* **callbackQueue**: 请求的回调 Block 执行的 dispatch 队列（线程），如果为 `NULL`（默认），那么会在一个私有的并发队列（子线程）中执行回调 Block。
* **engine**: 底层请求的引擎，默认为 `[XMEngine sharedEngine]` 单例对象，你也可以初始化一个 `XMEngine` 对象给它赋值。
* **consoleLog**: 一个 `BOOL` 值，用于表示是否在控制台输出请求和响应的信息，默认为 `NO`。

另外，你可以通过调用 `XMCenter` 的以下两个类方法来随时修改全局公共的 header 和 parameter：

```objc
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;
+ (void)setGeneralParameterValue:(nullable NSString *)value forKey:(NSString *)key;
```

### 普通请求

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

**注意1：**可以通过以下两种方法设置一个请求对象的 URL 地址，但当 `server`、`api` 和 `url` 三个属性被同时赋值时，`url` 的优先级比较高，而此时 `server`、`api` 的值会被忽略。

```objc
request.url = @"http://example.com/v1/foo/bar";
```

```objc
// 如果 request.server 为 `nil`，且 request.useGeneralServer 为 `YES`，那么此时 request.server 会取 XMCenter.generalServer 的值。
request.server = @"http://example.com/v1/";
request.api = @"foo/bar";
```

**注意2：**一个请求对象的回调 Block (success/failure/finished/progress) 是非必需的（默认为 `nil`），XMCenter 提供了多个设置不同回调 Block 参数的方法用于发送请求。另外，需要注意的是，success/faillure/finished 等回调 Block 会在 XMCenter 设置的 `callbackQueue` 队列中被执行，但 progress 回调 Block 将在 NSURLSession 自己的队列中执行，而不是 `callbackQueue`。

#### POST

```objc
[XMCenter sendRequest:^(XMRequest *request) {
    //request.server = @"http://example.com/v1/"; // 可选，如果为空则读取 XMCenter.generalServer
    request.api = @"foo/bar";
    request.parameters = @{@"param1": @"value1", @"param2": @"value2"};
    request.httpMethod = kXMHTTPMethodPOST; // 可选，默认为 `POST`
    request.requestType = kXMRequestNormal; // 可选，默认为 `Normal`
} onSuccess:^(id responseObject) {
   NSLog(@"onSuccess: %@", responseObject);
} onFailure:^(NSError *error) {
   NSLog(@"onFailure: %@", error);
}];
```

#### 其他 HTTP 方法

XMRequest 同样支持其他 HTTP 方法，比如：`HEAD`, `DELETE`, `PUT`, `PATCH` 等，使用方式与上述类似，不再赘述。

详见 `XMConst`、`XMRequest` 和 `XMCenter` 等几个文件中的代码和注释。

### 上传请求

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

### 下载请求

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

### 序列化

`XMRequest` 中有两个属性 `requestSerializerType` 和 `responseSerializerType` 分别用于设置请求参数和响应结果的序列化类型。

其中，`XMRequestSerializerType` 和 `XMResponseSerializerType` 枚举的定义如下：

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

详见 `AFURLRequestSerialization.h` 和 `AFURLResponseSerialization.h` 获取更多细节。

### 预处理和后处理插件
#### 请求预处理
你可以通过 `[XMCenter setRequestProcessBlock:...]` 设置 XMCenter 的预处理插件，在这里给所有请求做统一处理，另外需要注意的是，这个 `requestProcessBlock` 只对普通/上传/下载的请求有效，而对于批量请求和链式请求中的 `XMRequest` 对象，则不会走这个逻辑。

```objc
[XMCenter setRequestProcessBlock:^(XMRequest *request) {
    // 自定义请求预处理逻辑
    request.httpMethod = kXMHTTPMethodPOST;
    request.requestSerializerType = kXMRequestSerializerRAW;
    request.responseSerializerType = kXMResponseSerializerRAW;
}];
```

#### 自定义响应结果的处理逻辑

通常地，一个请求成功结束时，会执行 success block，当有错误发生时，执行 failure block。然而，开发中更常见的情况是，即使是一个请求成功结束，我们也需要进一步处理，比如验证响应结果数据、判断与服务端商量好的业务错误码类型等，再决定执行 success block 还是 failure block。

现在，你可以调用 `[XMCenter setResponseProcessBlock:...]` 方法以 Block 注入的方式设置自定义的处理逻辑，当请求成功结束时，这个 Block 会在 success block 被执行前调用，如果传入 `*error` 参数被赋值，则接下来会执行 failure block。

**在这里你可以对全局请求统一做业务错误码判断、数据模型转换、网络缓存等操作！**

```objc
[XMCenter setResponseProcessBlock:^(XMRequest *request, id responseObject, NSError *__autoreleasing *error) {
    // 自定义响应结果处理逻辑，如果 `*error` 被赋值，则接下来会执行 failure block。
}];
```

### 批量请求

XMNetworking 支持同时发一组批量请求，这组请求在业务逻辑上相关，但请求本身是互相独立的，success block 会在所有请求都成功结束时才执行，而一旦有一个请求失败，则会执行 failure block。注：回调 Block 中的 `responseObjects` 和 `errors` 中元素的顺序与每个 XMRequest 对象在 `batchRequest.requestArray` 中的顺序一致。

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

`[XMCenter sendBatchRequest:...]` 方法会返回刚发起的新的 `XMBatchRequest` 对象对应的唯一标识符 `identifier`，你通过 `identifier` 调用 XMCenter 的 `cancelRequest:` 方法取消这组批量请求。

### 链式请求

XMNetworking 同样支持发一组链式请求，这组请求之间互相依赖，下一请求是否发送以及请求的参数取决于上一个请求的结果，success block 会在所有的链式请求都成功结束时才执行，而中间一旦有一个请求失败，则会执行 failure block。注：回调 Block 中的 `responseObjects` 和 `errors` 中元素的顺序与每个链式请求 `XMRequest` 对象的先后顺序一致。

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

`[XMCenter sendChainRequest:...]` 方法会返回刚发起的新的 `XMChainRequest` 对象对应的唯一标识符 `identifier`，你通过 `identifier` 调用 XMCenter 的 `cancelRequest:` 方法取消这组链式请求。

### 取消一个网络请求

当调用 `[XMCenter sendRequest:...]` 方法发送一个网络请求时，该方法会返回一个用于唯一标识该请求对象的 `identifier`（如果请求发送失败，该值为 `nil`）。在必要的时候，你可以通过这个 `identifier` 来取消当前网络请求（如果一个请求已经结束，这时再用 `identifier` 来取消该请求时，会直接忽略）。

```objc
// send a request
NSString identifier = [XMCenter sendRequest:^(XMRequest *request) {
    request.url = @"http://example.com/v1/foo/bar";
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

**注意：**调用 `XMCenter cancelRequest:onCancel:` 方法取消一个网络请求时，被取消的请求对象（如果存在）会以参数的形式传给 cancel block，另外 cancel block 是在当前调用 `cancelRequest:` 方法的线程中执行，并不是 XMCenter 的 `callbackQueue`。

### 网络可连接性检查

我们提供了两种方法用于获取网络的可连接性，分别如下：

```objc
[[XMCenter defaultCenter] isNetworkReachable];
// 该方法会返回一个 Bool 值用于表示当前网络是否可连接。

[[XMEngine sharedEngine] reachabilityStatus]; 
// 该方法会返回一个当前网络的状态值，-1 表示 `Unknown`，0 表示 `NotReachable，1 表示 `WWAN`，2 表示 `WiFi`	
```

详见 `AFNetworkReachabilityManager` 获取更多细节.

### HTTPS 请求的本地证书校验（SSL Pinning）

在你的应用程序包里添加 (pinned) 相应的 SSL 证书做校验有助于防止中间人攻击和其他安全漏洞。AFNetworking 的 `AFSecurityPolicy` 安全模块可以通过校验本地保存的证书或公钥帮助我们评估服务器是否可信任以及建立安全连接。

在 XMNetworking 中，我们对 `AFSecurityPolicy` 进行了封装以便于使用，你可以通过 XMCenter 的 `addSSLPinningURL:` 方法添加需要做 SSL Pinning 的域名：

```objc
[XMCenter addSSLPinningURL:@"https://example.com/"];
```

默认你只需要把该域名对应的 .cer 格式的证书拖拽到你的工程中即可（即 .cer 所在的 bundle 需要与 XMNetworking 代码所在的 bundle 一致）。如果你是以 `embedded framework` 的方式（Carthage）集成 XMNetworking，则需要通过以下方式添加证书：

```objc
// Add SSL Pinning Certificate
NSString *certPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"certificate file name" ofType:@"cer"];
NSData *certData = [NSData dataWithContentsOfFile:certPath];
[XMCenter addSSLPinningCert:certData];
[XMCenter addSSLPinningURL:@"https://example.com/"];
```

详见 `AFSecurityPolicy` 获取更多细节.

## 文档

详见 [XMNetworking Documents Link](http://cocoadocs.org/docsets/XMNetworking/).

## 单元测试
XMNetworking 包含了一系列单元测试，用于验证网络请求的正确性，详见 `XMNetworkingDemoTests` 文件夹中的测试案例。

## 结构

XMNetworking 的代码结构非常简洁和紧凑，只包含了 4 个核心文件：`XMConst.h` 用于定义全局常量枚举和 Block，`XMRequest`，`XMCenter` 和 `XMEngine` 则是核心类的声明和实现，具体的代码结构如下图所示：

![XMNetworking Structure](http://img.kangzubin.cn/xmnetworking/XMNetworking-structure.png)

## 待完善

* 支持断点下载
* 支持网络层缓存
* 兼容测试支持 tvOS/watchOS/OS X
* 更加强大的自定义模型转换
* 实现一套可扩展的插件机制，便于 XMNetworking 增加新功能

## 作者

* [Zubin Kang](https://kangzubin.cn)

## 贡献者
* [southpeak](https://github.com/southpeak)
* [Xcode-Men Team](http://www.jianshu.com/users/d509cc369c78/)

## 许可证
XMNetworking 使用 MIT 许可证，详情见 [LICENSE](https://github.com/kangzubin/XMNetworking/blob/master/LICENSE) 文件。

