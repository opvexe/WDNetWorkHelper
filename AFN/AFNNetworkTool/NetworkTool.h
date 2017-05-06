//
//  NetworkTool.h
//  AFN
//
//  Created by jieku on 2017/5/6.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking.h>

typedef NS_ENUM(NSInteger,RequestMethod){
    GET,
    POST,
    DOWNLOAD,
    UPLOAD,
};

typedef void (^RequestSuccess) (id requestData);
typedef void (^RequestFailure) (NSInteger code,NSError *error);
typedef void(^CPNetworkProgress)(NSProgress *progress);

@interface NetworkTool : NSObject

/**
 *  AFNManager单利
 */
+(NetworkTool *)sharedManager;

/**
 *  监听网络状态
 */
- (void)reachabilityManager;

/**
 *  设置请求超时时长（默认60s）
 *
 *  @param timeout 超时时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 *  设置公共参数
 *
 *  @param params 公参
 */
+ (void)setCommonParams:(NSDictionary *)params;

/**
 *  GET请求
 *
 *  @param url     请求地址
 *  @param params  参数
 *  @param success 成功回调
 *  @param failure 失败回调
 *
 *  @return NSURLSessionTask
 */
+ (NSURLSessionTask *)GET:(NSString *)url
                   Params:(NSDictionary *)params
                  Success:(RequestSuccess)success
                  Failure:(RequestFailure)failure;

/**
 *  POST请求
 *
 *  @param url     请求地址
 *  @param params  参数
 *  @param success 成功回调
 *  @param failure 失败回调
 *
 *  @return NSURLSessionTask
 */
+ (NSURLSessionTask *)POST:(NSString *)url
                    Params:(NSDictionary *)params
                   Success:(RequestSuccess)success
                   Failure:(RequestFailure)failure;

/**
 *  上传单个文件
 *
 *  @param url      请求地址
 *  @param params   参数
 *  @param filedata 文件数据
 *  @param name     服务器用来解析的字段
 *  @param filename 文件名
 *  @param mimeType mimetype
 *  @param success  成功回调
 *  @param failure  失败回调
 *  @param progress  上传进度
 *  @return NSURLSessionTask
 */
+ (NSURLSessionTask *)UPLOADSINGLEFILE:(NSString *)url
                                Params:(NSDictionary *)params
                              FileData:(NSData *)filedata
                                  Name:(NSString *)name
                              FileName:(NSString *)filename
                              MimeType:(NSString *)mimeType
                               progress:(CPNetworkProgress)progress
                               Success:(RequestSuccess)success
                               Failure:(RequestFailure)failure;

/**
 *  上传多个文件
 *
 *  @param url       请求地址
 *  @param params    参数
 *  @param fileArray 文件数组
 *  @param success   成功回调
 *  @param failure   失败回调
 *  @param progress  上传进度
 *  @return NSURLSessionTask
 */
+ (NSURLSessionTask *)UPLOADMULTIFILE:(NSString *)url
                               Params:(NSDictionary *)params
                            FileArray:(NSArray *)fileArray
                              Progress:(CPNetworkProgress)progress
                              Success:(RequestSuccess)success
                              Failure:(RequestFailure)failure;


/**
 *  上传 图片
 *
 *  @param url        请求地址
 *  @param params     参数
 *  @param images     图片
 *  @param progress   上传进度
 *  @param success    成功回调
 *  @param failure    失败回调
 *
 *  @return NSURLSessionDataTask
 */
+ (NSURLSessionDataTask *)uploadWithURL:(NSString *)url parameters:(NSDictionary *)params images:(NSArray<UIImage *> *)images name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType Progress:(CPNetworkProgress)progress success:(RequestSuccess)success failure:(RequestFailure)failure;

/**
 *    上传视频
 *
 *  @param parameters  参数
 *  @param videoPath  视频地址
 *  @param URL        URL
 *  @param success    成功回调
 *  @param failure    失败毁掉
 *  @param progress   上传进度
 */
+(void)uploadVideoWithParameters:(NSDictionary *)parameters withVideoPath:(NSString *)videoPath withURL:(NSString *)URL Progress:(CPNetworkProgress)progress Success:(RequestSuccess)success Failure:(RequestFailure)failure;

/**
 *  下载
 *
 *  @param url       请求地址
 *  @param params    参数
 *  @param success   成功回调
 *  @param failure   失败回调
 *  @param progress  下载进度
 *  @return NSURLSessionTask
 */
+ (NSURLSessionTask *)DOWNLOAD:(NSString *)url
                               Params:(NSDictionary *)params
                             Progress:(CPNetworkProgress)progress
                              Success:(RequestSuccess)success
                              Failure:(RequestFailure)failure;
@end
