//
//  Person.m
//  KVO+Runtime
//
//  Created by godyu on 2018/5/2.
//  Copyright © 2018年 godyu. All rights reserved.
//

#import "Person.h"
#import "NSObject+CCYKVO.h"

@implementation Person

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)ccy_observerValueForKeyPath:(NSString *)keyPath object:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%@ --- keyPath: %@, object: %@, change:%@, context : %@", self, keyPath, object, change, context);
}

- (void)setAge:(NSInteger)age {
    _age = age;
}


@end
