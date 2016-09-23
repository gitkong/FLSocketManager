/*
 * author 孔凡列
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 喜欢就给个like 和 star 喔~
 */

#import "FLSocketManager.h"
#import "SRWebSocket.h"
@interface FLSocketManager ()<SRWebSocketDelegate>
@property (nonatomic,strong)SRWebSocket *webSocket;

@property (nonatomic,assign)FLSocketStatus socketStatus;

@property (nonatomic,copy)FLSocketDidConnectBlock connect;

@property (nonatomic,copy)FLSocketDidReceiveBlock receive;

@property (nonatomic,copy)FLSocketDidFailBlock failure;

@property (nonatomic,copy)FLSocketDidCloseBlock close;

@property (nonatomic,weak)NSTimer *timer;

@property (nonatomic,copy)NSString *urlString;

@end

@implementation FLSocketManager


+ (instancetype)shareManager{
    static FLSocketManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.overtime = 1;
    });
    return instance;
}

- (void)fl_open:(NSString *)urlStr connect:(FLSocketDidConnectBlock)connect receive:(FLSocketDidReceiveBlock)receive failure:(FLSocketDidFailBlock)failure{
    [FLSocketManager shareManager].connect = connect;
    [FLSocketManager shareManager].receive = receive;
    [FLSocketManager shareManager].failure = failure;
    [self fl_open:urlStr];
}

- (void)fl_close:(FLSocketDidCloseBlock)close{
    [FLSocketManager shareManager].close = close;
    [self fl_close];
}

// Send a UTF8 String or Data.
- (void)fl_send:(id)data{
    switch ([FLSocketManager shareManager].socketStatus) {
        case FLSocketStatusConnected:
        case FLSocketStatusReceived:{
            NSLog(@"发送中。。。");
            [self.webSocket send:data];
            break;
        }
        case FLSocketStatusFailed:
            NSLog(@"发送失败");
            break;
        case FLSocketStatusClosedByServer:
            NSLog(@"已经关闭");
            break;
        case FLSocketStatusClosedByUser:
            NSLog(@"已经关闭");
            break;
    }
    
}

#pragma mark -- private method
- (void)fl_open:(NSString *)urlStr{
    self.urlString = urlStr;
    [self.webSocket close];
    self.webSocket.delegate = nil;
    
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}

- (void)fl_close{
    
    [self.webSocket close];
    self.webSocket = nil;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)fl_reconnect{
    if(self.socketStatus == FLSocketStatusFailed || self.socketStatus == FLSocketStatusClosedByServer){
        [self.timer invalidate];
        self.timer = nil;
        NSLog(@"正在重连");
        //重连
        [self fl_open:self.urlString];
    }
}

#pragma mark -- SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    NSLog(@"Websocket Connected");
    // 开启定时器
    if (self.timer == nil) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.overtime target:self selector:@selector(fl_reconnect) userInfo:nil repeats:YES];
        self.timer = timer;
    }
    [FLSocketManager shareManager].connect ? [FLSocketManager shareManager].connect() : nil;
    [FLSocketManager shareManager].socketStatus = FLSocketStatusConnected;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@":( Websocket Failed With Error %@", error);
    [FLSocketManager shareManager].socketStatus = FLSocketStatusFailed;
    [FLSocketManager shareManager].failure ? [FLSocketManager shareManager].failure(error) : nil;
    // 重连
    [self fl_reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    NSLog(@":( Websocket Receive With message %@", message);
    [FLSocketManager shareManager].socketStatus = FLSocketStatusReceived;
    [FLSocketManager shareManager].receive ? [FLSocketManager shareManager].receive(message,FLSocketReceiveTypeForMessage) : nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    NSLog(@"Closed Reason:%@  code = %zd",reason,code);
    if (reason) {
        [FLSocketManager shareManager].socketStatus = FLSocketStatusClosedByServer;
    }
    else{
        [FLSocketManager shareManager].socketStatus = FLSocketStatusClosedByUser;
    }
    [FLSocketManager shareManager].close ? [FLSocketManager shareManager].close(code,reason,wasClean) : nil;
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    [FLSocketManager shareManager].receive ? [FLSocketManager shareManager].receive(pongPayload,FLSocketReceiveTypeForPong) : nil;
}

- (void)dealloc{
    // Close WebSocket
    [self fl_close];
}

@end
