//
//  BWNSURLProtocol.m
//  BWNetworkInterceptor
//
//  Created by bairdweng on 2021/6/10.
//

#import "BWNSURLProtocol.h"
#import "BWNetworkInterceptor.h"
#import "DoraemonURLSessionDemux.h"
@interface BWNSURLProtocol ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSError *error;

@property (atomic, strong, readwrite) NSThread *clientThread;
@property (atomic, copy,   readwrite) NSArray *modes;
@property (atomic, strong, readwrite) NSURLSessionDataTask *task;

@end

@implementation BWNSURLProtocol

+ (DoraemonURLSessionDemux *)sharedDemux {
	static dispatch_once_t sOnceToken;
	static DoraemonURLSessionDemux *sDemux;
	dispatch_once(&sOnceToken, ^{
		NSURLSessionConfiguration *config;
		config = [NSURLSessionConfiguration defaultSessionConfiguration];
		sDemux = [[DoraemonURLSessionDemux alloc] initWithConfiguration:config];
	});
	return sDemux;
}
// 返回是否要处理拦截
+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
	NSURLRequest *request = task.currentRequest;
	return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	if ([NSURLProtocol propertyForKey:BWProtocolKey inRequest:request]) {
		return NO;
	}
	if (![BWNetworkInterceptor shareInstance].shouldIntercept) {
		return NO;
	}
	if (![request.URL.scheme isEqualToString:@"http"] &&
	    ![request.URL.scheme isEqualToString:@"https"]) {
		return NO;
	}
	//文件类型不作处理
	NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
	if (contentType && [contentType containsString:@"multipart/form-data"]) {
		return NO;
	}
	return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	NSMutableURLRequest *mutableReqeust = [request mutableCopy];
	[NSURLProtocol setProperty:@YES forKey:BWProtocolKey inRequest:mutableReqeust];
	{
		// 这里可以做mock拦截
	}
	return [mutableReqeust copy];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
	assert([NSThread currentThread] == self.clientThread);
	self.response = response;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	assert([NSThread currentThread] == self.clientThread);
	[self.data appendData:data];
	[self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

#pragma mark - 函数重写
- (void)startLoading {
	NSMutableURLRequest *   recursiveRequest;
	NSMutableArray *        calculatedModes;
	NSString *              currentMode;
	assert(self.clientThread == nil);
	assert(self.task == nil);
	assert(self.modes == nil);

	calculatedModes = [NSMutableArray array];
	[calculatedModes addObject:NSDefaultRunLoopMode];
	currentMode = [[NSRunLoop currentRunLoop] currentMode];
	if ( (currentMode != nil) && ![currentMode isEqual:NSDefaultRunLoopMode] ) {
		[calculatedModes addObject:currentMode];
	}
	self.modes = calculatedModes;
	assert([self.modes count] > 0);

	recursiveRequest = [[self request] mutableCopy];
	assert(recursiveRequest != nil);

	self.clientThread = [NSThread currentThread];
	self.data = [NSMutableData data];
	self.startTime = [[NSDate date] timeIntervalSince1970];
	self.task = [[[self class] sharedDemux] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
	assert(self.task != nil);
	// 可以拦截？
	if([BWNetworkInterceptor shareInstance].weakDelegate) {
		[self handleFromSelect];
	}else{
		[self.task resume];
	}
}

- (void)stopLoading {
	// 任务停止
	if (self.task != nil) {
		[self.task cancel];
		self.task = nil;
	}
}

- (void)handleFromSelect {
	// 如果有实现拦截协议，那么这里延迟之后再执行嘛
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[BWNetworkInterceptor shareInstance].weakDelegate delayTime] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self.task resume];
	});
}

@end


