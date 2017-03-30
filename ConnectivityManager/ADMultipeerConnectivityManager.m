//
//  ADMultipeerConnectivityManager.m
//  MultipeerConnectivityTest
//
//  Created by WhenWe on 2017/3/28.
//  Copyright © 2017年 HaierYunchu. All rights reserved.
//

#import "ADMultipeerConnectivityManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ADMultipeerConnectivityManager ()<MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate, MCSessionDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) id <ADMultipeerConnectivityDelegate> delegate;

@property (nonatomic, copy) ADMultipeerSuccessCallBack success;
@property (nonatomic, copy) ADMultipeerFailedCallBack fail;

@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCBrowserViewController *browserVC;

@property (nonatomic, strong) MCPeerID *remotePeerID;

@property (nonatomic, strong) NSMutableDictionary *searchBrowserDic;


@property (nonatomic, strong) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic, copy) void (^invitationHandler)(BOOL, MCSession * _Nullable);

@end

@implementation ADMultipeerConnectivityManager

+ (instancetype)managerWithType:(ADMultipeerConnectivityType)type delegate:(id <ADMultipeerConnectivityDelegate>)delegate
{
    ADMultipeerConnectivityManager *manager = [[ADMultipeerConnectivityManager alloc] initWithType:type];
    manager.delegate = delegate;
    return manager;
}

- (instancetype)initWithType:(ADMultipeerConnectivityType)type
{
    self = [super init];
    if (self) {
        self.type = type;
        self.session.delegate = self;
        self.peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    }
    return self;
}

- (MCPeerID *)peerID
{
    if (!_peerID) {
        _peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    return _peerID;
}

- (void)setType:(ADMultipeerConnectivityType)type
{
    _type = type;
    if (type == ADMultipeerConnectivityTypePost) {

        [self startSearch];
    }
}

- (MCSession *)session
{
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    }
    return _session;
}

- (MCBrowserViewController *)browserVC
{
    if (!_browserVC) {
        _browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"whenWeStream" session:self.session];
        _browserVC.delegate = self;
        _browserVC.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
        _browserVC.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;
    }
    return _browserVC;
}

- (NSMutableDictionary *)searchBrowserDic
{
    if (!_searchBrowserDic) {
        _searchBrowserDic = [NSMutableDictionary dictionary];
    }
    return _searchBrowserDic;
}

#pragma mark - Control
/**
 发起搜索周围接收源
 */
- (void)startSearch
{
//    [self.browser startBrowsingForPeers];
    [(UIViewController *)self.delegate presentViewController:self.browserVC animated:YES completion:nil];
}

///**
// 请求建立连接
//
// @param name 对方显示名字
// */
//- (void)connectWithPeerDisplayName:(NSString *)name
//{
//    MCPeerID *peerID = [self.searchBrowserDic valueForKey:name];
////    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
//}

/**
 向对方发送数据

 @param fileURL 本地文件的url
 */
- (void)sendResourceURL:(NSURL *)fileURL
{
     self.progress = [self.session sendResourceAtURL:fileURL withName:[fileURL.absoluteString lastPathComponent] toPeer:self.remotePeerID withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            if ([self.delegate respondsToSelector:@selector(manager:didSendDataProgress:peerName:error:)]) {
                [self.delegate manager:self didSendDataProgress:0 peerName:self.peerID.displayName error:[NSError errorWithDomain:@"" code:-1 userInfo:@{NSLocalizedDescriptionKey : error.localizedDescription}]];
            }
        } else {
            [self.browserVC dismissViewControllerAnimated:YES completion:^{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"发送成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [av show];
            }];
            if ([self.delegate respondsToSelector:@selector(manager:didSendDataProgress:peerName:error:)]) {
                [self.delegate manager:self didSendDataProgress:0 peerName:self.peerID.displayName error:[NSError errorWithDomain:@"" code:1 userInfo:@{NSLocalizedDescriptionKey : @"发送成功"}]];
            }
        }
         [self.progress removeObserver:self forKeyPath:@"completedUnitCount"];
    }];
    [self.progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
}

/** 监听
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"completedUnitCount"]) {
        NSProgress *progress = (NSProgress *)object;
        if ([self.delegate respondsToSelector:@selector(manager:didSendDataProgress:peerName:error:)]) {
            [self.delegate manager:self didSendDataProgress:progress peerName:self.peerID.displayName error:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey : @"发送中"}]];
        }
    }
}

#pragma mark - MCBrowserViewControllerDelegate
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info
{
    __block BOOL have = NO;

    [self.searchBrowserDic.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:peerID.displayName]) {
            have = YES;
        }
    }];

    if (!have) {
        [self.searchBrowserDic setObject:peerID forKey:peerID.displayName];
        if ([self.delegate respondsToSelector:@selector(manager:didSearchResult:success:)]) {
            [self.delegate manager:self didSearchResult:self.searchBrowserDic.allKeys success:YES];
        }
    }

    return YES;
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}


/** 连接状态发生变化
 */
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
        {
            NSLog(@"连接成功");
            self.remotePeerID = peerID;
            if ([self.delegate respondsToSelector:@selector(manager:didChangeConnectState:peerName:)]) {
                [self.delegate manager:self didChangeConnectState:ADMultipeerConnectivityConnectStateConnected peerName:peerID.displayName];
            }
        }
            break;

        case MCSessionStateConnecting:
        {
            NSLog(@"连接中");
            if ([self.delegate respondsToSelector:@selector(manager:didChangeConnectState:peerName:)]) {
                [self.delegate manager:self didChangeConnectState:ADMultipeerConnectivityConnectStateConnecting peerName:peerID.displayName];
            }
        }
            break;

        default:
        {
            NSLog(@"连接失败");
            if ([self.delegate respondsToSelector:@selector(manager:didChangeConnectState:peerName:)]) {
                [self.delegate manager:self didChangeConnectState:ADMultipeerConnectivityConnectStateFail peerName:peerID.displayName];
            }
        }
            break;
    }
}

#pragma mark - 接收
#pragma mark -
//- (MCNearbyServiceAdvertiser *)advertiser
//{
//    if (!_advertiser) {
//        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:@"whenWe-send"];
//        _advertiser.delegate = self;
//    }
//    return _advertiser;
//}

- (MCAdvertiserAssistant *)advertiserAssistant
{
    if (!_advertiserAssistant) {
        _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"whenWeStream" discoveryInfo:nil session:self.session];
        _advertiserAssistant.delegate = self;
    }
    return _advertiserAssistant;
}

/**
 开始监听周围数据
 */
- (void)startObserveConnectApply
{
//    [self.advertiser startAdvertisingPeer];
    [self.advertiserAssistant start];
}

/**
 接受连接请求
 */
- (void)acceptConnectApply:(BOOL)accept
{
    self.invitationHandler(accept, self.session);
}

#pragma mark - MCAdvertiserAssistantDelegate
- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{

}

- (void)advertiserAssistantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    
}



- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    self.progress = progress;
    [progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    [self.progress removeObserver:self forKeyPath:@"completedUnitCount"];

    if (error) {
        if ([self.delegate respondsToSelector:@selector(manager:didSendDataProgress:peerName:error:)]) {
            [self.delegate manager:self didSendDataProgress:0 peerName:peerID.displayName error:[NSError errorWithDomain:@"" code:-1 userInfo:@{NSLocalizedDescriptionKey : error.localizedDescription}]];
        }
    } else {
        //接收到数据后本地处理  回调   delegate
        if ([self.delegate respondsToSelector:@selector(manager:didSendDataProgress:peerName:error:)]) {
            [self.delegate manager:self didSendDataProgress:0 peerName:peerID.displayName error:[NSError errorWithDomain:@"" code:1 userInfo:@{NSLocalizedDescriptionKey : @"接收成功", @"localURL" : localURL, @"resourceName" : [resourceName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]}]];
        }
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{

}

@end
