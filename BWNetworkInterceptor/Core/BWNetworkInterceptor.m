//
//  BWNetworkInterceptor.m
//  BWNetworkInterceptor
//
//  Created by bairdweng on 2021/6/10.
//

#import "BWNetworkInterceptor.h"
#import "BWNSURLProtocol.h"
static BWNetworkInterceptor *instance = nil;

@interface BWNetworkInterceptor ()<BWNetworkInterceptorWeakDelegate>

@end

@implementation BWNetworkInterceptor

+ (instancetype)shareInstance {
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		instance = [[BWNetworkInterceptor alloc] init];
	});
	return instance;
}
- (instancetype)init
{
	self = [super init];
	if (self) {
		[self setUp];
        self.weakDelegate = self;
	}
	return self;
}

- (void)setUp {
	[NSURLProtocol registerClass:[BWNSURLProtocol class]];
}

- (NSUInteger)delayTime {
	
    return 2;
}

- (void)handleWeak:(nonnull NSData *)data isDown:(BOOL)is {
    
}


@end
