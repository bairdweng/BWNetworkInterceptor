//
//  ViewController.m
//  BWNetworkInterceptor
//
//  Created by bairdweng on 2021/6/10.
//

#import "ViewController.h"
#import "BWNetworkInterceptor.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// 是否需要拦截
	[BWNetworkInterceptor shareInstance].shouldIntercept = YES;
//    [BWNetworkInterceptor shareInstance];
	// Do any additional setup after loading the view.
}

- (IBAction)clickOntheRequest:(id)sender {
	// 模拟请求
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=1056001690,3524418889&fm=26&gp=0.jpg"]];
		NSLog(@"data================%@",data);
	});
}

@end
