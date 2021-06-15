//
//  BWNetworkInterceptor.h
//  BWNetworkInterceptor
//
//  Created by bairdweng on 2021/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
static NSString * const BWProtocolKey = @"BW_protocol_key";

@protocol BWNetworkInterceptorWeakDelegate <NSObject>
- (void)handleWeak:(NSData *)data isDown:(BOOL)is;
// 延迟时间弱网连接。
- (NSUInteger)delayTime;
@end

@interface BWNetworkInterceptor : NSObject
+ (instancetype)shareInstance;
/// 是否要拦截
@property(nonatomic, assign) BOOL shouldIntercept;

@property (nonatomic, weak) id<BWNetworkInterceptorWeakDelegate> weakDelegate;
@end
NS_ASSUME_NONNULL_END
