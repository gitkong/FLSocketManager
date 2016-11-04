/*
 * author 孔凡列
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 喜欢就给个like 和 star 喔~
 */

#import <Foundation/Foundation.h>

/**
 *  @author 孔凡列
 *
 *  socket状态
 */
typedef NS_ENUM(NSInteger,FLSocketStatus){
    FLSocketStatusConnected,// 已连接
    FLSocketStatusFailed,// 失败
    FLSocketStatusClosedByServer,// 系统关闭
    FLSocketStatusClosedByUser,// 用户关闭
    FLSocketStatusReceived// 接收消息
};
/**
 *  @author 孔凡列
 *
 *  消息类型
 */
typedef NS_ENUM(NSInteger,FLSocketReceiveType){
    FLSocketReceiveTypeForMessage,
    FLSocketReceiveTypeForPong
};
/**
 *  @author 孔凡列
 *
 *  连接成功回调
 */
typedef void(^FLSocketDidConnectBlock)();
/**
 *  @author 孔凡列
 *
 *  失败回调
 */
typedef void(^FLSocketDidFailBlock)(NSError *error);
/**
 *  @author 孔凡列
 *
 *  关闭回调
 */
typedef void(^FLSocketDidCloseBlock)(NSInteger code,NSString *reason,BOOL wasClean);
/**
 *  @author 孔凡列
 *
 *  消息接收回调
 */
typedef void(^FLSocketDidReceiveBlock)(id message ,FLSocketReceiveType type);

@interface FLSocketManager : NSObject
/**
 *  @author 孔凡列
 *
 *  连接回调
 */
@property (nonatomic,copy)FLSocketDidConnectBlock connect;
/**
 *  @author 孔凡列
 *
 *  接收消息回调
 */
@property (nonatomic,copy)FLSocketDidReceiveBlock receive;
/**
 *  @author 孔凡列
 *
 *  失败回调
 */
@property (nonatomic,copy)FLSocketDidFailBlock failure;
/**
 *  @author 孔凡列
 *
 *  关闭回调
 */
@property (nonatomic,copy)FLSocketDidCloseBlock close;
/**
 *  @author 孔凡列
 *
 *  当前的socket状态
 */
@property (nonatomic,assign,readonly)FLSocketStatus fl_socketStatus;
/**
 *  @author 孔凡列
 *
 *  超时重连时间，默认1秒
 */
@property (nonatomic,assign)NSTimeInterval overtime;
/**
 *  @author Clarence
 *
 *  重连次数,默认5次
 */
@property (nonatomic, assign)NSUInteger reconnectCount;
/**
 *  @author 孔凡列
 *
 *  单例调用
 */
+ (instancetype)shareManager;
/**
 *  @author 孔凡列
 *
 *  开启socket
 *
 *  @param urlStr  服务器地址
 *  @param connect 连接成功回调
 *  @param receive 接收消息回调
 *  @param failure 失败回调
 */
- (void)fl_open:(NSString *)urlStr connect:(FLSocketDidConnectBlock)connect receive:(FLSocketDidReceiveBlock)receive failure:(FLSocketDidFailBlock)failure;
/**
 *  @author 孔凡列
 *
 *  关闭socket
 *
 *  @param close 关闭回调
 */
- (void)fl_close:(FLSocketDidCloseBlock)close;
/**
 *  @author 孔凡列
 *
 *  发送消息，NSString 或者 NSData
 *
 *  @param data Send a UTF8 String or Data.
 */
- (void)fl_send:(id)data;

@end
