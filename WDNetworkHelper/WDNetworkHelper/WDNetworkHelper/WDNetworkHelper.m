//
//  WDNetworkHelper.m
//  WDNetworkHelper
//
//  Created by Facebook on 2018/7/31.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "WDNetworkHelper.h"
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAsset.h>
#import <AFNetworking.h>
#import "WDNetworkCache.h"
#import "WDSessionManger.h"

#define WD_ERROR [NSError errorWithDomain:@"com.Networking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:@"网络出现错误，请检查网络连接"}]
static BOOL isDebug = YES;  // 打印日志
static BOOL _shouldAutoEncode = NO;
static NSMutableArray   *requestTasks;
static WDSessionManger *_sessionManager;
@implementation WDNetworkHelper

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasks == nil) requestTasks = [NSMutableArray array];
    });
    return requestTasks;
}

/// MARK: 取消所有请求队列
+ (void)cancelAllRequest{
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSURLSessionTask class]]) {
                [obj cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    }
}

/// MARK: 取消指定url请求队列
+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) return;
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSURLSessionTask class]]) {
                if ([obj.currentRequest.URL.absoluteString hasSuffix:url]) {
                    [obj cancel];
                    *stop = YES;
                }
            }
        }];
    }
}

#pragma mark   请求方法 【Method】
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                  success:(WDHttpRequestSuccess)success
                  failure:(WDHttpRequestFailed)failure{
    return  [self WithMethodGET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

+ ( NSURLSessionTask *)GET:(NSString *)URL
                parameters:(NSDictionary *)parameters
             responseCache:(WDHttpRequestCache)responseCache
                   success:(WDHttpRequestSuccess)success
                   failure:(WDHttpRequestFailed)failure{
    return  [self WithMethodGET:URL parameters:parameters responseCache:responseCache success:success failure:failure];
}

+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
                   success:(WDHttpRequestSuccess)success
                   failure:(WDHttpRequestFailed)failure{
    return [self WithMethodPOST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
             responseCache:(WDHttpRequestCache)responseCache
                   success:(WDHttpRequestSuccess)success
                   failure:(WDHttpRequestFailed)failure{
    return [self WithMethodPOST:URL parameters:parameters responseCache:responseCache success:success failure:failure];
}

///MARK: GET 公共请求
+ (NSURLSessionTask *)WithMethodGET:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(WDHttpRequestCache)responseCache
                            success:(WDHttpRequestSuccess)success
                            failure:(WDHttpRequestFailed)failure {
    
    NSURLSessionTask *sessionTask ;
    
    
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return sessionTask;
    }
    
    responseCache!=nil ? responseCache([WDNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
    if ([self shouldEncode]) {
        URL = [self http_URLEncode:URL];
    }
    
    sessionTask  = [_sessionManager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allTasks] removeObject:task];
        success ? success([self tryToParseData:responseObject]) : nil;
        
        if (responseCache!=nil) {
            [WDNetworkCache setHttpCache:responseObject URL:URL parameters:parameters];
        }
        if (isDebug) {
            [self logWithSuccessResponse:responseObject
                                     url:task.response.URL.absoluteString
                                  params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        [[self allTasks] removeObject:task];
        if (isDebug) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:parameters];
        }
    }];
    
    sessionTask ? [[self allTasks] addObject:sessionTask] : nil ;
    return sessionTask;
}

///MARK: POST 公共请求
+ (NSURLSessionTask *)WithMethodPOST:(NSString *)URL
                          parameters:(NSDictionary *)parameters
                       responseCache:(WDHttpRequestCache)responseCache
                             success:(WDHttpRequestSuccess)success
                             failure:(WDHttpRequestFailed)failure {
    
    NSURLSessionTask *sessionTask ;
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return sessionTask;
    }
    
    responseCache!=nil ? responseCache([WDNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
    if ([self shouldEncode]) {
        URL = [self http_URLEncode:URL];
    }
    
    sessionTask  = [_sessionManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allTasks] removeObject:task];
        success ? success([self tryToParseData:responseObject]) : nil;
        
        if (responseCache!=nil) {
            [WDNetworkCache setHttpCache:responseObject URL:URL parameters:parameters];
        }
        if (isDebug) {
            [self logWithSuccessResponse:responseObject
                                     url:task.response.URL.absoluteString
                                  params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        [[self allTasks] removeObject:task];
        if (isDebug) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:parameters];
        }
    }];
    
    sessionTask ? [[self allTasks] addObject:sessionTask] : nil ;
    return sessionTask;
}

///MARK: 上传多张图片
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(NSDictionary *)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(WDHttpProgress)progress
                                  success:(WDHttpRequestSuccess)success
                                  failure:(WDHttpRequestFailed)failure{
    
    NSURLSessionTask *sessionTask ;
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return sessionTask;
    }
    
    sessionTask  = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"] : imageFileName
                                    mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allTasks] removeObject:task];
        success ? success([self tryToParseData:responseObject]) : nil;
        
        if (isDebug) {
            [self logWithSuccessResponse:responseObject
                                     url:task.response.URL.absoluteString
                                  params:parameters];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        [[self allTasks] removeObject:task];
        if (isDebug) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:parameters];
        }
    }];
    
    sessionTask ? [[self allTasks] addObject:sessionTask] : nil ;
    return sessionTask;
}

///MARK: 多文件上传
+(NSArray *)uploadMultFileWithURL:(NSString *)URL
                       parameters:(NSDictionary *)parameters
                        fileDatas:(NSArray *)filePaths
                             name:(NSString *)name
                         progress:(WDHttpProgress)progress
                          success:(WDHttpRequestSuccess)success
                          failure:(WDHttpRequestFailed)failure{
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return nil;
    }
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    dispatch_group_t uploadGroup = dispatch_group_create();
    for (int i = 0; i<filePaths.count; i++) {
        NSURLSessionDataTask *dataTask= nil;         //group同步
        dispatch_group_enter(uploadGroup);
        dataTask = [self uploadFileWithURL:URL parameters:parameters name:name filePath:filePaths[i] progress:^(NSProgress *UPprogress) {
            progress ? progress(UPprogress) : nil;
        } success:^(id responseObject) {
            [responses addObject:responseObject];
            dispatch_group_leave(uploadGroup);
            [sessions removeObject:dataTask];
        } failure:^(NSError *error) {
            NSError *Error = [NSError errorWithDomain:URL code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
            [failResponse addObject:Error];
            dispatch_group_leave(uploadGroup);
            [sessions removeObject:dataTask];
        }];
        [dataTask resume];
        if (dataTask) [sessions addObject:dataTask];
    }
    [[self allTasks] addObjectsFromArray:sessions];
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (success) {
                success([responses copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        if (failResponse.count > 0) {
            if (failure) {
                failure([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
    });
    return [sessions copy];
}
///MARK: 上传文件
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                             parameters:(NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)filePath
                               progress:(WDHttpProgress)progress
                                success:(WDHttpRequestSuccess)success
                                failure:(WDHttpRequestFailed)failure{
    NSURLSessionTask *sessionTask ;
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return sessionTask;
    }
    
    sessionTask  = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        (failure && error) ? failure(error) : nil;
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allTasks] removeObject:task];
        success ? success([self tryToParseData:responseObject]) : nil;
        
        if (isDebug) {
            [self logWithSuccessResponse:responseObject
                                     url:task.response.URL.absoluteString
                                  params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        [[self allTasks] removeObject:task];
        if (isDebug) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:parameters];
        }
    }];
    
    sessionTask ? [[self allTasks] addObject:sessionTask] : nil ;
    return sessionTask;
}

///MARK: 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(WDHttpProgress)progress
                              success:(void(^)(NSString *filePath))success
                              failure:(WDHttpRequestFailed)failure{
    NSURLSessionTask *downloadTask ;
    if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
        failure?failure(WD_ERROR):nil;
        return downloadTask;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress ? progress(downloadProgress) : nil;
        NSLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (fileDir.length) {
            return [NSURL fileURLWithPath:fileDir];
        }else{
            NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];    //打开文件管理器
            NSFileManager *fileManager = [NSFileManager defaultManager]; //创建Download目录
            [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];//拼接文件路径
            NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
            NSLog(@"downloadDir = %@",downloadDir);             //返回文件位置的URL路径
            return [NSURL fileURLWithPath:filePath];
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        success ? success(filePath.absoluteString) : nil;
        failure && error ? failure(error) : nil;
    }];
    
    [downloadTask resume];  //开始下载
    if (downloadTask) [[self allTasks] addObject:downloadTask];
    return downloadTask;
}

///MARK: 上传视频
+(void)uploadVideoWithURL:(NSString *)URL
               parameters:(NSDictionary *)parameters
                VideoPath:(NSString *)videoPath
                 progress:(WDHttpProgress)progress
                  success:(WDHttpRequestSuccess)success
                  failure:(WDHttpRequestFailed)failure{
    
    AVURLAsset * avAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:videoPath]];
    /*
     压缩
     NSString *const AVAssetExportPreset640x480;
     NSString *const AVAssetExportPreset960x540;
     NSString *const AVAssetExportPreset1280x720;
     NSString *const AVAssetExportPreset1920x1080;
     NSString *const AVAssetExportPreset3840x2160;
     */
    AVAssetExportSession  *  avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *  videoWritePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:[NSString stringWithFormat:@"/SPI-%@.mp4",[formatter stringFromDate:[NSDate date]]]];
    avAssetExport.outputURL = [NSURL URLWithString:videoWritePath];
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([avAssetExport status]) {
            case AVAssetExportSessionStatusCompleted:{
                if (self.currentNetWorkStatus == WDNetworkStatusNotReachable) {
                    failure?failure(WD_ERROR):nil;
                }
                AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
                
                [manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoWritePath] name:@"上传视频" fileName:videoWritePath mimeType:@"video/mpeg4" error:nil];
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    progress(uploadProgress);
                } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
                    success ? success(responseObject) : nil;
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    failure ? failure(error) : nil;
                }];
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark   编码/打印
+(NSString *)http_URLEncode:(NSString *)url{
    NSString *newString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)url,NULL,CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    return url;
}

///MARK: 打印日志
+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    NSLog(@"\nabsoluteUrl: %@\n params:%@\n response:%@\n\n",
          [self generateGETAbsoluteURL:url params:params],
          params,
          [self tryToParseData:response]);
}
+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(NSDictionary *)params {
    NSLog(@"\nabsoluteUrl: %@\n params:%@\n errorInfos:%@\n\n",
          [self generateGETAbsoluteURL:url params:params],
          params,
          [error localizedDescription]);
}

+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(NSDictionary *)params{
    if (params.count ==0) {
        return url;
    }
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        }else if ([value isKindOfClass:[NSArray class]]){
            continue;
        }else if ([value isKindOfClass:[NSSet class]]){
            continue;
        }else{
            queries = [NSString stringWithFormat:@"%@%@=%@&",(queries.length==0? @"&":queries),key,value];
        }
    }
    if (queries.length>1) {
        queries = [queries substringToIndex:queries.length -1];
    }
    if (([url rangeOfString:@"http://"].location !=NSNotFound ||[url rangeOfString:@"https://"].location !=NSNotFound)&&queries.length>1) {
        if ([url rangeOfString:@"?"].location !=NSNotFound ||[url rangeOfString:@"#"].location !=NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@",url,queries];
        }else{
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@",url,queries];
        }
    }
    return url.length==0?queries:url;
}

+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        if (responseData ==nil) {
            return  responseData;
        }else{
            NSError *error = nil;
            NSDictionary *respose = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                return  responseData;
            }else{
                return respose;
            }
        }
    }else{
        return responseData;
    }
}

#pragma mark  Set方法
+ (void)initialize {
    _sessionManager = [WDSessionManger manager];
    _sessionManager.responseSerializer.stringEncoding = NSUTF8StringEncoding;
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    _sessionManager.securityPolicy = securityPolicy;
    [_sessionManager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [_sessionManager.requestSerializer setTimeoutInterval:30.0];
    [_sessionManager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",@"text/json", @"text/javascript",@"text/html", @"text/plain",@"application/atom+xml",@"application/xml",@"text/xml", @"image/*",]];
    _sessionManager.operationQueue.maxConcurrentOperationCount = 3;
    
    /*  设置https单向认证
     securityPolicy.allowInvalidCertificates = NO;
     [securityPolicy setValidatesDomainName:YES];
     [_sessionManager setSecurityPolicy:[self customSecurityPolicy]];
     */
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setRequestSerializer:(WDRequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = requestSerializer==WDRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(WDResponseSerializer)responseSerializer {
    switch (responseSerializer) {
        case WDResponseSerializerJSON:{
            _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        }
            break;
        case WDResponseSerializerHTTP:{
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        }
            break;
        case WDNetworkResponseTypeXML:{
            _sessionManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
        }
            break;
        default:{
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        }
            break;
    }
}

+(void)configPublicHttpHeaders:(NSDictionary *)httpHeaders{
    if (httpHeaders.count) {
        [httpHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [_sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
}

+(void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode{
    _shouldAutoEncode = shouldAutoEncode;
}

+(BOOL)shouldEncode{
    return _shouldAutoEncode;
}

#pragma mark 双向认证/单向认证
+ (AFSecurityPolicy*)customSecurityPolicy{
    // /先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"" ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    // AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    securityPolicy.pinnedCertificates = @[certData];
    return securityPolicy;
}

///MARK: 获取当前网络
+(WDNetworkStatusType )currentNetWorkStatus{
    UIApplication *application = [UIApplication sharedApplication];
    NSMutableArray *chlidrenArray = [NSMutableArray arrayWithCapacity:0];
    if ([[application valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
        chlidrenArray = [[[[application valueForKeyPath:@"_statusBar"] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews].mutableCopy;
    } else {
        chlidrenArray =  [[[application valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews].mutableCopy;
    }
    NSUInteger state = 0;
    NSInteger netType =0;
    for (id  child in chlidrenArray) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            netType = [[child valueForKeyPath:@"dataNetworkType"] integerValue];
            switch (netType) {
                case 0:
                    state = WDNetworkStatusNotReachable;
                    break;
                case 1:
                    state = WDNetworkStatusReachableViaWWAN;
                    break;
                case 2:
                    state = WDNetworkStatusReachableViaWWAN;
                    break;
                case 3:
                    state = WDNetworkStatusReachableViaWWAN;
                    break;
                case 5:
                    state = WDNetworkStatusReachableViaWiFi;
                    break;
                default:
                    break;
            }
        }
    }
    return state;
}

@end
