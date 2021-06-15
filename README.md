# NSURLProtocol 网络拦截

通常我们需要模拟一些弱网测试，或者数据的拦截，这里主要采用NSURLProtocol的方法。关键代码如下。

1. 注册实现协议的类。

   ```objective-c
   	[NSURLProtocol registerClass:[BWNSURLProtocol class]];
   ```

2. 关键性代码重写函数

   ```objective-c
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
   
   ```

3. 具体请查看Demo