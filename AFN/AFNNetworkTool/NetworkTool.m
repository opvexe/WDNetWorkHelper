//
//  NetworkTool.m
//  AFN
//
//  Created by jieku on 2017/5/6.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "NetworkTool.h"

static NSString         *base_url = nil;
static NSTimeInterval   time_out = 60.0f;
static NSDictionary     *common_params = nil;

@interface NetworkTool()
{
    //    AFHTTPRequestOperation *operation; //创建请求管理（用于上传和下载）
}
@end
static NetworkTool *manager = nil;

@implementation NetworkTool


/**
 *  创建请求管理者
 *
 *  @return 对应的对象：AFNManager单利
 */
+(NetworkTool *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[self alloc] init];
        }
    });
    return manager;
}


/**
 *  初始化内存
 */
+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            
            manager = [super allocWithZone:zone];
        }
    });
    return manager;
}


+ (void)setTimeout:(NSTimeInterval)timeout {
    time_out = timeout;
}

+ (void)setCommonParams:(NSDictionary *)params {
    common_params = params;
}

/**
 *  拼接完整的URL
 */

+ (NSString *)print:(NSString *)url params:(NSDictionary *)params
{
    NSMutableString *absURL = [NSMutableString string];
    [absURL appendString:url];
    __block BOOL first = YES;
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *keyvalue;
        if (first == YES)
        {
            keyvalue = [NSString stringWithFormat:@"?%@=%@",key,obj];
            first = NO;
        }
        else
        {
            keyvalue = [NSString stringWithFormat:@"&%@=%@",key,obj];
        }
        
        [absURL appendString:keyvalue];
    }];
    return absURL;
}


/**
 *  设置AFHTTPSessionManager相关属性
 */

+(AFHTTPSessionManager *)manager{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.stringEncoding = NSUTF8StringEncoding;
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = time_out;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",@"text/html",@"text/json",@"text/plain",@"text/javascript",@"text/xml",@"image/*"]];
    //    [manager setSecurityPolicy:[self customSecurityPolicy]]; 设置证书
    //    [self  checkCredential:manager]; //校验证书
    manager.operationQueue.maxConcurrentOperationCount = 6;
    
    return manager;
}

/**
 *  GET请求
 */

+ (NSURLSessionTask *)GET:(NSString *)url Params:(NSDictionary *)params Success:(RequestSuccess)success Failure:(RequestFailure)failure {
    return [self RequestWithUrl:url RequestMethod:GET Params:params FileArray:nil Success:(RequestSuccess)success Failure:(RequestFailure)failure];
}

/**
 *  POST请求
 */

+ (NSURLSessionTask *)POST:(NSString *)url Params:(NSDictionary *)params Success:(RequestSuccess)success Failure:(RequestFailure)failure {
    return [self RequestWithUrl:url RequestMethod:POST Params:params FileArray:nil Success:success Failure:failure];
}

/**
 *   上传文件
 */

+ (NSURLSessionTask *)UPLOADSINGLEFILE:(NSString *)url Params:(NSDictionary *)params FileData:(NSData *)filedata Name:(NSString *)name FileName:(NSString *)filename MimeType:(NSString *)mimeType   progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"data"] = filedata;
    dict[@"name"] = name;
    dict[@"filename"] = filename;
    dict[@"mimeType"] = mimeType;
    return [self RequestWithUrl:url RequestMethod:UPLOAD Params:params FileArray:@[dict] Progress:progress Success:success Failure:failure];
}

/**
 *   上传多文件
 */

+ (NSURLSessionTask *)UPLOADMULTIFILE:(NSString *)url Params:(NSDictionary *)params FileArray:(NSArray *)fileArray  progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure {
    return [self RequestWithUrl:url RequestMethod:UPLOAD Params:params FileArray:fileArray Progress:progress Success:success Failure:failure];
}

/**
 *   下载
 */
+ (NSURLSessionTask *)DOWNLOAD:(NSString *)url Params:(NSDictionary *)params Progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure{
    
    return [self RequestWithUrl:url RequestMethod:DOWNLOAD Params:params FileArray:nil Progress:progress Success:success Failure:failure];
}

/**
 *   GET&&POST
 */

+ (NSURLSessionTask *)RequestWithUrl:(NSString *)url RequestMethod:(RequestMethod)method Params:(NSDictionary *)params FileArray:(NSArray *)fileArray Success:(RequestSuccess)success Failure:(RequestFailure)failure{
    
    AFHTTPSessionManager *manager = [self manager];
    
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    if (common_params != nil) {
        [requestParams addEntriesFromDictionary:common_params];
    }
    if (params != nil) {
        [requestParams addEntriesFromDictionary:params];
    }
    
    NSURLSessionTask *session = nil;
    NSString *requestUrl = [NSString stringWithFormat:@"%@",url];
    
    NSLog(@"%@ = %@",url,[self print:requestUrl params:requestParams]);
    
    if (method == GET) {
        session = [manager GET:url parameters:requestParams progress:^(NSProgress * _Nonnull downloadProgress) {
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure([error code],error);
        }];
    }else if (method == POST) {
        session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure([error code],error);
        }];
    }
    return session;
}

/**
 *   UPLOAD&&UPLOADLIST
 */
+ (NSURLSessionTask *)RequestWithUrl:(NSString *)url RequestMethod:(RequestMethod)method Params:(NSDictionary *)params FileArray:(NSArray *)fileArray Progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure{
    
    AFHTTPSessionManager *manager = [self manager];
    
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    if (common_params != nil) {
        [requestParams addEntriesFromDictionary:common_params];
    }
    if (params != nil) {
        [requestParams addEntriesFromDictionary:params];
    }
    
    NSURLSessionTask *session = nil;
    NSString *requestUrl = [NSString stringWithFormat:@"%@",url];
    
    NSLog(@"%@ = %@",url,[self print:requestUrl params:requestParams]);
    
    if (method == UPLOAD) {
        
        session = [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSError *error;
            if (fileArray == nil || fileArray.count == 0) {
                failure([error code],error);
            }else {
                [fileArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDictionary *dict = obj;
                    NSData *filedata = dict[@"data"];
                    NSString *name = dict[@"name"];
                    NSString *filename = dict[@"filename"];
                    NSString *mimeType = dict[@"mimeType"];
                    [formData appendPartWithFileData:filedata name:name fileName:filename mimeType:mimeType];
                }];
            }
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            progress?progress(uploadProgress):nil;
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure([error code],error);
        }];
    }else if (method==DOWNLOAD){
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        session = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            progress?progress(downloadProgress):nil;
            NSLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            
            //拼接缓存目录
            NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];
            //打开文件管理器
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            //创建Download目录
            [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
            
            //拼接文件路径
            NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
            
            NSLog(@"downloadDir = %@",downloadDir);
            //返回文件位置的URL路径
            return [NSURL fileURLWithPath:filePath];
        }completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            failure([error code],error);
        }];
    }
    return  session;
}

/**
 *   IMAGEUPLOAD
 */
+ (NSURLSessionDataTask *)uploadWithURL:(NSString *)url parameters:(NSDictionary *)params images:(NSArray<UIImage *> *)images name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType Progress:(CPNetworkProgress)progress success:(RequestSuccess)success failure:(RequestFailure)failure{
    
    AFHTTPSessionManager *manager = [self manager];
    
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    if (common_params != nil) {
        [requestParams addEntriesFromDictionary:common_params];
    }
    if (params != nil) {
        [requestParams addEntriesFromDictionary:params];
    }
    
    NSURLSessionDataTask *dataTask = nil;
    NSString *requestUrl = [NSString stringWithFormat:@"%@",url];
    
    NSLog(@"%@ = %@",url,[self print:requestUrl params:requestParams]);
    
    dataTask = [manager POST:requestUrl parameters:requestParams  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //压缩-添加-上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            [formData appendPartWithFileData:imageData name:name fileName:[NSString stringWithFormat:@"%@%lu.%@",fileName,(unsigned long)idx,mimeType?mimeType:@"jpeg"] mimeType:[NSString stringWithFormat:@"image/%@",mimeType?mimeType:@"jpeg"]];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure([error code],error);
    }];
    
    [dataTask resume];
    return dataTask;
}

/**
 *   UPLOADVideo
 */
+(void)uploadVideoWithParameters:(NSDictionary *)parameters withVideoPath:(NSString *)videoPath withURL:(NSString *)URL Progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure{
    
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
            case AVAssetExportSessionStatusCompleted:
            {
                AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
                [manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoWritePath] name:@"video" fileName:videoWritePath mimeType:@"video/mpeg4" error:nil];
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    progress?progress(uploadProgress):nil;
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    success(responseObject);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    failure([error code],error);
                }];
            }
                break;
                
            default:
                break;
        }
    }];
}
//网络监听（用于检测网络是否可以链接。此方法最好放于AppDelegate中，可以使程序打开便开始检测网络）
- (void)reachabilityManager
{
    AFHTTPSessionManager *mgr = [AFHTTPSessionManager manager];
    //打开网络监听
    [mgr.reachabilityManager startMonitoring];
    
    //监听网络变化
    [mgr.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
                
                //当网络不可用（无网络或请求延时）
            case AFNetworkReachabilityStatusNotReachable:
                break;
                
                //当为手机WiFi时
            case AFNetworkReachabilityStatusReachableViaWiFi:
                break;
                
                //当为手机蜂窝数据网
            case AFNetworkReachabilityStatusReachableViaWWAN:
                break;
                
                //其它情况
            default:
                break;
        }
    }];
    
    //    //停止网络监听（若需要一直检测网络状态，可以不停止，使其一直运行）
    //    [mgr.reachabilityManager stopMonitoring];
}

+ (AFSecurityPolicy*)customSecurityPolicy{
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    NSString * cerPath = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"cer"];     //导入证书
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    NSSet   *dataSet = [NSSet setWithArray:@[certData]];
    [securityPolicy setAllowInvalidCertificates:YES];//是否允许使用自签名证书
    [securityPolicy setPinnedCertificates:dataSet];//设置去匹配服务端证书验证的证书
    [securityPolicy setValidatesDomainName:NO];//是否需要验证域名，默认YES
    
    return securityPolicy;
}

#pragma mark 校验证书
- (void)checkCredential:(AFURLSessionManager *)manager
{
    [manager setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
    }];
    __weak typeof(manager)weakManager = manager;
    [manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __autoreleasing NSURLCredential *credential =nil;
        NSLog(@"authenticationMethod=%@",challenge.protectionSpace.authenticationMethod);
        //判断服务器要求客户端的接收认证挑战方式，如果是NSURLAuthenticationMethodServerTrust则表示去检验服务端证书是否合法，NSURLAuthenticationMethodClientCertificate则表示需要将客户端证书发送到服务端进行检验
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            // 基于客户端的安全策略来决定是否信任该服务器，不信任的话，也就没必要响应挑战
            if([weakManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                // 创建挑战证书（注：挑战方式为UseCredential和PerformDefaultHandling都需要新建挑战证书）
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                // 确定挑战的方式
                if (credential) {
                    //证书挑战  设计policy,none，则跑到这里
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else { //只有双向认证才会走这里
            // client authentication
            SecIdentityRef identity = NULL;
            SecTrustRef trust = NULL;
            NSString *p12 = [[NSBundle mainBundle] pathForResource:@"client"ofType:@"p12"];
            NSFileManager *fileManager =[NSFileManager defaultManager];
            
            if(![fileManager fileExistsAtPath:p12])
            {
                NSLog(@"client.p12:not exist");
            }
            else
            {
                NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
                
                if ([self extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
                {
                    SecCertificateRef certificate = NULL;
                    SecIdentityCopyCertificate(identity, &certificate);
                    const void*certs[] = {certificate};
                    CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                    credential =[NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                    disposition =NSURLSessionAuthChallengeUseCredential;
                }
            }
        }
        *_credential = credential;
        return disposition;
    }];
}

#pragma mark 读取p12的密码
- (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    OSStatus securityError = errSecSuccess;
    //client certificate password
    NSDictionary*optionsDictionary = [NSDictionary dictionaryWithObject:@"csykum812"
                                                                 forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if(securityError == 0) {
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity =NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust =NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failedwith error code %d",(int)securityError);
        return NO;
    }
    return YES;
}

@end
