//
//  ViewController.m
//  FLSocketDemo
//
//  Created by clarence on 16/9/24.
//  Copyright © 2016年 clarence. All rights reserved.
//

#import "ViewController.h"
#import "FLSocketManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     *  @author 孔凡列, 16-09-21 08:09:06
     *
     *  开启连接
     */
    NSString *url = @"服务器给你的地址";
    [[FLSocketManager shareManager] fl_open:url connect:^{
        NSLog(@"成功连接");
    } receive:^(id message, FLSocketReceiveType type) {
        if (type == FLSocketReceiveTypeForMessage) {
            NSLog(@"接收 类型1--%@",message);
        }
        else if (type == FLSocketReceiveTypeForPong){
            NSLog(@"接收 类型2--%@",message);
        }
    } failure:^(NSError *error) {
        NSLog(@"连接失败");
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[FLSocketManager shareManager] fl_close:^(NSInteger code, NSString *reason, BOOL wasClean) {
        NSLog(@"code = %zd,reason = %@",code,reason);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [[FLSocketManager shareManager] fl_send:@"hello world"];
}

@end
