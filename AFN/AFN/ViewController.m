//
//  ViewController.m
//  AFN
//
//  Created by jieku on 2017/5/6.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "ViewController.h"
#import "NetworkTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
 [NetworkTool GET:@"www.hao123.com" Params:nil Success:^(id requestData) {
     NSLog(@"%@",requestData);
 } Failure:^(NSInteger code, NSError *error) {
     
 }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
