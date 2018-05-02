//
//  ViewController.m
//  KVO+Runtime
//
//  Created by godyu on 2018/5/2.
//  Copyright © 2018年 godyu. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import <objc/runtime.h>
#import "NSObject+CCYKVO.h"

@interface ViewController ()

@property (nonatomic, strong)Person *p;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _p = [Person new];
  
    [self ccy_addObserver:self forKeyPath:@"_p.name" options:CCY_NSKeyValueObservingOptionNew | CCY_NSKeyValueObservingOptionOld | CCY_NSKeyValueObservingOptionPrior context:nil];
    [self ccy_addObserver:_p forKeyPath:@"_p.name" options:CCY_NSKeyValueObservingOptionNew context:nil];
    
    self.p.name = @"world";
//
//    [self ccy_removeObserver:self forKeyPath:@"_p.name"];
//    
//    [self ccy_removeObserver:_p forKeyPath:@"_p.name"];
}

- (void)ccy_observerValueForKeyPath:(NSString *)keyPath object:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"yb_ %@ --- keyPath: %@, object: %@, change: %@, context: %@", self, keyPath, object, change, context);
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _p.name = @"陈春宇";
}



@end
