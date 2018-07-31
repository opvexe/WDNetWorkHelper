//
//  WDNetworkHelper.h
//  WDNetworkHelper
//
//  Created by Facebook on 2018/7/31.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WDNetworkStatusType) {
    /// 未知网络
    WDNetworkStatusUnknown,
    /// 无网络
    WDNetworkStatusNotReachable,
    /// 手机网络
    WDNetworkStatusReachableViaWWAN,
    /// WIFI网络
    WDNetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, WDRequestSerializer) {
    /// 设置请求数据为二进制格式
    WDRequestSerializerHTTP,
    /// 设置请求数据为JSON格式
    WDRequestSerializerJSON,
};

typedef NS_ENUM(NSUInteger, WDResponseSerializer) {
    /// 设置响应数据为JSON格式
    WDResponseSerializerJSON,
    /// 设置响应数据为二进制格式
    WDResponseSerializerHTTP,
    /// 设置响应数据为XML格式
    WDNetworkResponseTypeXML
};

/// 请求成功的Block
typedef void(^WDHttpRequestSuccess)(id responseObject);
/// 请求失败的Block
typedef void(^WDHttpRequestFailed)(NSError *error);
/// 缓存的Block
typedef void(^WDHttpRequestCache)(id responseCache);
/// 上传或者下载的进度
typedef void (^WDHttpProgress)(NSProgress *progress);
/// 网络状态Block
typedef void(^WDNetworkStatus)(WDNetworkStatusType status);

@interface WDNetworkHelper : NSObject
/// 获取当前网络状态
@property (nonatomic,assign)WDNetworkStatusType currentNetWorkStatus;
/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;
/// 取消所有HTTP请求
+ (void)cancelAllRequest;
/// 设置超时时间：默认30秒
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;
/// 设置网络请求参数的格式:默认为二进制格式
+ (void)setRequestSerializer:(WDRequestSerializer)requestSerializer;
/// 设置服务器响应数据格式:默认为JSON格式
+ (void)setResponseSerializer:(WDResponseSerializer)responseSerializer;
/// 设置请求头
+(void)configPublicHttpHeaders:(NSDictionary *)httpHeaders;
/// URL编码
+(void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode;

/**
 *  GET请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(WDHttpRequestSuccess)success
                           failure:(WDHttpRequestFailed)failure;

/**
 *  GET请求,缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                     responseCache:(WDHttpRequestCache)responseCache
                           success:(WDHttpRequestSuccess)success
                           failure:(WDHttpRequestFailed)failure;

/**
 *  POST请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            success:(WDHttpRequestSuccess)success
                            failure:(WDHttpRequestFailed)failure;

/**
 *  POST请求,缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(WDHttpRequestCache)responseCache
                            success:(WDHttpRequestSuccess)success
                            failure:(WDHttpRequestFailed)failure;

/**
 *  上传文件
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param name       文件对应服务器上的字段
 *  @param filePath   文件本地的沙盒路径
 *  @param progress   上传进度信息
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                                      parameters:(NSDictionary *)parameters
                                            name:(NSString *)name
                                        filePath:(NSString *)filePath
                                        progress:(WDHttpProgress)progress
                                         success:(WDHttpRequestSuccess)success
                                         failure:(WDHttpRequestFailed)failure;


/**
 * 上传多文件

 @param URL 请求地址
 @param parameters 请求参数
 @param filePaths 文件本地的沙盒路径
 @param name  文件对应服务器上的字段
 @param progress  上传进度信息
 @param success  请求成功的回调
 @param failure 请求失败的回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+(__kindof NSArray *)uploadMultFileWithURL:(NSString *)URL
                                parameters:(NSDictionary *)parameters
                                 fileDatas:(NSArray *)filePaths
                                      name:(NSString *)name
                                  progress:(WDHttpProgress)progress
                                   success:(WDHttpRequestSuccess)success
                                   failure:(WDHttpRequestFailed)failure;

/**
 *  上传单/多张图片
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param name       图片对应服务器上的字段
 *  @param images     图片数组
 *  @param fileNames  图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 *  @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
 *  @param imageType  图片文件的类型,例:png、jpg(默认类型)....
 *  @param progress   上传进度信息
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                                        parameters:(NSDictionary *)parameters
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(WDHttpProgress)progress
                                           success:(WDHttpRequestSuccess)success
                                           failure:(WDHttpRequestFailed)failure;

/**
 *  下载文件
 *
 *  @param URL      请求地址
 *  @param fileDir  文件存储目录(默认存储目录为Download)
 *  @param progress 文件下载的进度信息
 *  @param success  下载成功的回调(回调参数filePath:文件的路径)
 *  @param failure  下载失败的回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
 */
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                       fileDir:(NSString *)fileDir
                                      progress:(WDHttpProgress)progress
                                       success:(void(^)(NSString *filePath))success
                                       failure:(WDHttpRequestFailed)failure;


/**
 * 上传视频
 
 * @param URL 请求地址
 * @param parameters 请求参数
 * @param videoPath 上传文件地址
 * @param progress 文件上传的进度信息
 * @param success 上传成功的回调
 * @param failure 上传失败的回调
 *
 */
+(void)uploadVideoWithURL:(NSString *)URL
               parameters:(NSDictionary *)parameters
                VideoPath:(NSString *)videoPath
                 progress:(WDHttpProgress)progress
                  success:(WDHttpRequestSuccess)success
                  failure:(WDHttpRequestFailed)failure;
@end
