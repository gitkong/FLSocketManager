## 一、简单介绍

SocketRocket是一个WebSocket客户端（[WebSocket](http://tools.ietf.org/html/rfc6455)是适用于Web应用的下一代全双工通讯协议，被成为“Web的TCP”，它实现了浏览器与服务器的双向通信），采用Object-C编写。SocketRocket遵循最新的WebSocket规范[RFC 6455](http://tools.ietf.org/html/rfc6455)。

这里是开发者描述的其一些特性/设计： 
> 
支持TLS (wss)。
使用NSStream/CFNetworking。
使用ARC。
采用并行架构。大部分的工作由后端的工作队列（worker queues）完成。
基于委托编程。

SocketRocket支持iOS 4.x系统（应该也可以运行于OS X），不需要任何UI包依赖。详细信息可以查看[此文介绍](http://corner.squareup.com/2012/02/socketrocket-websockets.html)。 

### [socketRocket 传送门](https://github.com/facebook/SocketRocket)  


## 二、如何使用
 - ####socketRocket 支持pod，因此直接添加然后install，文件不多喔~

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1085031-c34c45a1d56a86ee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

-  ####简单使用socketRocket实现通信的话，只需要用那么几个API就行了

> 1.创建一个请求：（有多种方法）

```
- (id)initWithURLRequest:(NSURLRequest *)request;
```

>2.遵守并指定代理

```
@property (nonatomic, weak) id <SRWebSocketDelegate> delegate;
```

>3.打开连接加载请求

```
- (void)open;
```

>4.关闭连接

```
- (void)close;
```

>5.发送消息

```
// Send a UTF8 String or Data.
- (void)send:(id)data;
// Send Data (can be nil) in a ping message.
- (void)sendPing:(NSData *)data;
```

>6.监听socketRocket是通过代理方法来实现的

```
@protocol SRWebSocketDelegate <NSObject>
// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
@optional
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
// Return YES to convert messages sent as Text to an NSString. Return NO to skip NSData -> NSString conversion for Text messages. Defaults to YES.
- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket;
```

- ####注意：发送的参数必须跟后台商量，保持一致才能发送，不然一发送就自动关闭连接的

## 三、封装隔离

- #### 为什么要封装
 -  我就按上面的6个步骤就可以实现通信了，不用考虑太多的逻辑处理，但我还是觉得有点麻烦，我希望一句代码就搞定，使用代理就实现不了。
 -  第三方框架必须要封装隔离，不然Facebook突然改了这个框架的API，那么你项目多次使用的话，改动工作量就非常大了。
 - 我需要它有个重连机制，如果连接失败或者系统异常原因导致连接关闭的话，它会自动重连，如果是用户手动关闭，则不需要重连，直到下次重新打开。

- #### 封装思路
 -  需要单例工具类，管理socket的状态,当然状态是不允许外界修改，因此是readonly
 -  对外提供超时重连的时间，允许外界修改
 -  对外提供开启连接方法，使用block进行回调，不使用代理，实现一句代码创建并监听
 - 有开启必须有关闭连接的方法，同样使用block回调，告诉调用者关闭的状态码以及原因
 -  当然需要一个发送方法，参数模仿框架，传id类型就行

- ####封装后的API（.h文件）

>自定义的枚举，socket状态，比框架多一个枚举是用户关闭

```
/**
 *  @author 孔凡列, 16-09-21 07:09:52
 *
 *  socket状态
 */
typedef NS_ENUM(NSInteger,FLSocketStatus){
    FLSocketStatusConnected,// 已连接
    FLSocketStatusFailed,// 失败
    FLSocketStatusClosedByServer,// 系统关闭
    FLSocketStatusClosedByUser,// 用户关闭
    FLSocketStatusReceived// 接收消息
};
/**
 *  @author 孔凡列, 16-09-21 07:09:52
 *
 *  消息类型
 */
typedef NS_ENUM(NSInteger,FLSocketReceiveType){
    FLSocketReceiveTypeForMessage,
    FLSocketReceiveTypeForPong
};

```

> 连接回调，成功连接后执行

```

/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  连接回调
 */
@property (nonatomic,copy)FLSocketDidConnectBlock connect;

```

>接收到socket消息的时候就会执行

```
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  接收消息回调
 */
@property (nonatomic,copy)FLSocketDidReceiveBlock receive;

```

>连接或发送失败会执行

```
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  失败回调
 */
@property (nonatomic,copy)FLSocketDidFailBlock failure;

```

>用户手动关闭或者系统关闭的时候会调用

```
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  关闭回调
 */
@property (nonatomic,copy)FLSocketDidCloseBlock close;

```

>socket状态，一共有5个状态

```
/**
 *  @author 孔凡列, 16-09-21 08:09:28
 *
 *  当前的socket状态
 */
@property (nonatomic,assign,readonly)FLSocketStatus fl_socketStatus;

```

>超时重连时间，默认一秒重连（框架没有，自己添加的）

```
/**
 *  @author 孔凡列, 16-09-21 08:09:40
 *
 *  超时重连时间，默认1秒
 */
@property (nonatomic,assign)NSTimeInterval overtime;
```

>超时重连次数，默认5次（框架没有，自己添加的）

```
/**
 *  @author Clarence
 *
 *  重连次数,默认5次
 */
@property (nonatomic, assign)NSUInteger reconnectCount;
```

>单例创建管理类，项目中唯一，方便管理

```
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  单例调用
 */
+ (instancetype)shareManager;
```

>开启socket，block监听

```
/**
 *  @author 孔凡列, 16-09-21 08:09:16
 *
 *  开启socket
 *
 *  @param urlStr  服务器地址
 *  @param connect 连接成功回调
 *  @param receive 接收消息回调
 *  @param failure 失败回调
 */
- (void)fl_open:(NSString *)urlStr connect:(FLSocketDidConnectBlock)connect receive:(FLSocketDidReceiveBlock)receive failure:(FLSocketDidFailBlock)failure;
```

>关闭socket，有两个状态，一个是用户关闭，一个是系统关闭

```
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  关闭socket
 *
 *  @param close 关闭回调
 */
- (void)fl_close:(FLSocketDidCloseBlock)close;
```

>发送消息，可发送NSString 或者 NSData

```
/**
 *  @author 孔凡列, 16-09-21 08:09:25
 *
 *  发送消息，NSString 或者 NSData
 *
 *  @param data Send a UTF8 String or Data.
 */
- (void)fl_send:(id)data;

```



## 四、调用

>#### 1、开启连接并监听
```
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
```
#### 2、发送消息
```
[[FLSocketManager shareManager] fl_send:@"hello world"];
```
#### 3、关闭连接
```
[[FLSocketManager shareManager] fl_close:^(NSInteger code, NSString *reason, BOOL wasClean) {
        NSLog(@"code = %zd,reason = %@",code,reason);
    }];
```

## 五、总结 
 - 使用block回调，用法只需要三步，监听都在同一个方法里面，方便管理，关键是看起来简单，用起来爽，而且不怕框架API修改

 - 有重连机制，连接失败或者系统异常原因导致关闭的就会自动重连，默认一秒就重连，如果调用者手动关闭就不重连，有最大重连次数，可自定义，默认5次

- 实现部分的代码就拷贝上来了，喜欢的话就去clone吧，demo没有给服务器地址，实测没问题的

- 一般socket开启后就不用关闭，此时作者封装的这个block是单例对象的，因此如果另一个控制器监听了接收block，那么前一个控制器就没办法监听接收，建议大家使用通知去实现，只需要在一个控制器去做监听，然后发通知，其他控制器监听这个通知就行，这样就可以实现整个项目多个控制器都能同时监听socket改变

## 欢迎大家去[我的简书](http://www.jianshu.com/users/fe5700cfb223/latest_articles)关注我，随时发干货，喜欢就给个star && like，有问题留言哟~~~
