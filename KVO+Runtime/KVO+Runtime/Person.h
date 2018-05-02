//
//  Person.h
//  KVO+Runtime
//
//  Created by godyu on 2018/5/2.
//  Copyright © 2018年 godyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic, copy)NSString *name;
@property (nonatomic, assign)NSInteger age;
@property (nonatomic, copy)NSString *love;

@end
