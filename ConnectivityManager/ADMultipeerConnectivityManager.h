//
//  ADMultipeerConnectivityManager.h
//  MultipeerConnectivityTest
//
//  Created by WhenWe on 2017/3/28.
//  Copyright © 2017年 HaierYunchu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ADMultipeerSuccessCallBack)(id);
typedef void(^ADMultipeerFailedCallBack)(NSError *error);

/** 请求类型
 */
typedef NS_ENUM(NSUInteger, ADMultipeerConnectivityType) {
    ADMultipeerConnectivityTypeRecieve,//接收数据
    ADMultipeerConnectivityTypePost//发送数据
};

/** 同远程设备连接状态
 */
typedef NS_ENUM(NSUInteger, ADMultipeerConnectivityConnectState) {
    ADMultipeerConnectivityConnectStateConnected,//连接成功
    ADMultipeerConnectivityConnectStateConnecting,//连接中
    ADMultipeerConnectivityConnectStateFail,//连接失败
};

/** 数据传输状态 接收/发送
 */
typedef NS_ENUM(NSUInteger, ADMultipeerConnectivityDataTransmissionState) {
    ADMultipeerConnectivityDataTransmissionStateSuccess,//数据传输成功
    ADMultipeerConnectivityDataTransmissionStateTransmissing,//数据传输中
    ADMultipeerConnectivityDataTransmissionStateFail,//数据传输失败
};












#pragma mark - ADMultipeerConnectivityDelegate
#pragma mark -
@class ADMultipeerConnectivityManager;
@protocol ADMultipeerConnectivityDelegate <NSObject>


/** 连接的状态 发送方/接收方
 */
- (void)manager:(ADMultipeerConnectivityManager *)manager didChangeConnectState:(ADMultipeerConnectivityConnectState)state peerName:(NSString *)peerDisplyName;

/** 发送文件的状态 发送方/接收方
 isSend 是发送方  还是  接收方

 error
    .code:-1失败 0:发送中 1:发送成功
    localURL(NSURL类型，只有isSend为NO时存在):接收到的文件存在的路径 可以直接使用 或使用fileManager moveItemAtURL:localURL toURL:
    resourceName:资源名称
 */
- (void)manager:(ADMultipeerConnectivityManager *)manager didSendDataProgress:(NSProgress *)progress peerName:(NSString *)peerDisplyName error:(NSError *)error;





@optional
/** 搜索的结果 发送方
 */
- (void)manager:(ADMultipeerConnectivityManager *)manager didSearchResult:(NSArray *)array success:(BOOL)success;



/** 接收到连接请求后的处理 接收方
        acceptCallBack(YES或NO);
 */
- (void)manager:(ADMultipeerConnectivityManager *)manager didRecievedConnectApply:(NSString *)peerName;


@end










#pragma mark - ADMultipeerConnectivityManager
#pragma mark -
@interface ADMultipeerConnectivityManager : NSObject

@property (nonatomic, readonly, assign) ADMultipeerConnectivityType type;
+ (instancetype)managerWithType:(ADMultipeerConnectivityType)type delegate:(id <ADMultipeerConnectivityDelegate>)delegate;

#pragma mark -发送方
/**
 发起搜索周围接收源
 */
- (void)startSearch;

///**
// 请求建立连接
//
// @param name 对方显示名字
// */
//- (void)connectWithPeerDisplayName:(NSString *)name;


/**
 向对方发送数据

 @param fileURL 本地文件的url
 */
- (void)sendResourceURL:(NSURL *)fileURL;



#pragma mark -接收方
/**
 开始监听周围数据
 */
- (void)startObserveConnectApply;

/**
 接受连接请求
 */
- (void)acceptConnectApply:(BOOL)accept;

@end
