//
//  NSObject+CCYKVO.h
//  KVO+Runtime
//
//  Created by godyu on 2018/5/2.
//  Copyright © 2018年 godyu. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, CCY_NSKeyValueObservingOptions) {
    CCY_NSKeyValueObservingOptionNew = 0x01,
    CCY_NSKeyValueObservingOptionOld = 0x02,
    CCY_NSKeyValueObservingOptionInitial = 0x04,
    CCY_NSKeyValueObservingOptionPrior = 0x08
    
};

@interface NSObject (CCYKVO)

- (void)ccy_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(CCY_NSKeyValueObservingOptions)options context:(void *)context;
- (void)ccy_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context;
- (void)ccy_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
- (void)ccy_observerValueForKeyPath:(NSString *)keyPath object:(id)object change:(NSDictionary *)change context:(void *)context;

@end
