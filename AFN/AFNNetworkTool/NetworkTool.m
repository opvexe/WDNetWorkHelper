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
    manager.requestSerializer.timeoutInterval = time_out;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",@"text/html",@"text/json",@"text/plain",@"text/javascript",@"text/xml",@"image/*"]];
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

+ (AFSecurityPolicy*)customSecurityPolicy
{
    
    //证书路径
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


@end
