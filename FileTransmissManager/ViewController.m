//
//  ViewController.m
//  FileTransmissManager
//
//  Created by WhenWe on 2017/3/30.
//  Copyright © 2017年 HaierYunchu. All rights reserved.
//

#import "ViewController.h"
#import "ADMultipeerConnectivityManager.h"

@interface ViewController ()<ADMultipeerConnectivityDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) ADMultipeerConnectivityManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.


    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:nil];

    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"------%@", obj);
    }];


}

- (IBAction)searchDevices:(UIBarButtonItem *)sender {
    self.manager = [ADMultipeerConnectivityManager managerWithType:ADMultipeerConnectivityTypePost delegate:self];
    [self.manager startSearch];
}


- (void)manager:(ADMultipeerConnectivityManager *)manager didChangeConnectState:(ADMultipeerConnectivityConnectState)state peerName:(NSString *)peerDisplyName
{
    NSString *tipStr = @"连接成功";
    if (state == ADMultipeerConnectivityConnectStateFail) {
        tipStr = @"连接失败";
    } else if (state == ADMultipeerConnectivityConnectStateConnecting) {
        tipStr = @"连接中";
    }
    self.title = [NSString stringWithFormat:@"与%@%@", peerDisplyName, tipStr];

    if (state == ADMultipeerConnectivityConnectStateConnected) {
        if (manager.type == ADMultipeerConnectivityTypePost) {
            //发送文件
            NSString *path = [[NSBundle mainBundle]pathForResource:@"薛之谦 - 演员" ofType:@"mp3"];
            [self.manager sendResourceURL:[NSURL fileURLWithPath:path]];
        }
    }
}

- (void)manager:(ADMultipeerConnectivityManager *)manager didSendDataProgress:(NSProgress *)progress peerName:(NSString *)peerDisplyName error:(NSError *)error
{
    NSString *str = @"接收";
    if (manager.type == ADMultipeerConnectivityTypePost) {
        str = @"发送";
    }
    if (error.code == 0) {//发送中或接收中
        NSLog(@"----已%@%.2f%%", str, (double)progress.completedUnitCount / progress.totalUnitCount * 100);
    } else if (error.code == 1) {
        if (manager.type == ADMultipeerConnectivityTypeRecieve) {
            NSLog(@"接收成功");

            NSString *toPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject ;
            toPath =[toPath stringByAppendingPathComponent:[error.userInfo objectForKey:@"resourceName"]];

            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"接收文件成功" message:[error.userInfo objectForKey:@"resourceName"] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [av show];

            NSError *error1;
            [[NSFileManager defaultManager]moveItemAtURL:error.userInfo[@"localURL"] toURL:[NSURL fileURLWithPath:toPath] error:&error1];
        } else {
            NSLog(@"发送成功");
        }
    }
    
}







- (IBAction)waitForRecieveApply:(UIBarButtonItem *)sender {
    self.manager = [ADMultipeerConnectivityManager managerWithType:ADMultipeerConnectivityTypeRecieve delegate:self];
    [self.manager startObserveConnectApply];
}

- (void)manager:(ADMultipeerConnectivityManager *)manager didRecievedConnectApply:(NSString *)peerName
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"是否接受%@的连接请求", peerName] message:nil delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
    av.tag = 0;
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0) {
        if (buttonIndex == 0) {
            [self.manager acceptConnectApply:NO];
        } else if (buttonIndex == 1) {
            [self.manager acceptConnectApply:YES];
        }
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
