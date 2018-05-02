//
//  NSObject+CCYKVO.m
//  KVO+Runtime
//
//  Created by godyu on 2018/5/2.
//  Copyright © 2018年 godyu. All rights reserved.
//

#import "NSObject+CCYKVO.h"
#import <objc/message.h>

const void *keyOfCCYKVOInfoModel = &keyOfCCYKVOInfoModel;
NSString *kPrefixOfCCYKVO = @"kPrefixOfCCYKVO_";

@interface CCYKVOInfoModel : NSObject {
    void *_context;
}

- (void)setContext: (void *)context;
- (void *)getContext;

@property (nonatomic, weak)id target;
@property (nonatomic, weak)id observer;
@property (nonatomic, copy)NSString *keyPath;
@property (nonatomic, assign)CCY_NSKeyValueObservingOptions options;

@end

@implementation CCYKVOInfoModel

- (void)dealloc {
    _context = NULL;
}

- (void)setContext:(void *)context {
    _context = context;
}
- (void *)getContext {
    return _context;
}

@end


static NSString * setterNameFromGetterName(NSString *getterName) {
    if (getterName.length < 1) return nil;
    NSString *setterName;
    //转换为大写的字符串
    setterName = [getterName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[getterName substringToIndex:1] uppercaseString]];
    setterName = [NSString stringWithFormat:@"set%@:", setterName];
    return setterName;
}

static NSString *getterNameFromSetterName(NSString *setterName) {
    if (setterName.length < 1 || ![setterName hasPrefix:@"set"] || ![setterName hasSuffix:@":"]) return nil;
    NSString *getterName;
    getterName = [setterName substringWithRange:NSMakeRange(3, setterName.length - 4)];
    getterName = [getterName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[getterName substringToIndex:1] lowercaseString]];
    return getterName;
}

static inline int classHasSel(Class class, SEL sel) {
    unsigned int outCount = 0;
    Method *methods = class_copyMethodList(class, &outCount);
    for (int i = 0; i < outCount; i++) {
        Method method = methods[i];
        SEL mSel = method_getName(method);
        if (mSel == sel) {
            free(methods);
            return 1;
        }
    }
    free(methods);
    return 0;
}

//回调设置
static void callBack(id target, id newValue, id oldValue, NSString *getterName, BOOL notificationIsPrior) {
    
    NSMutableDictionary *dic = objc_getAssociatedObject(target, keyOfCCYKVOInfoModel);
    if (dic && [dic valueForKey:getterName]) {
        NSMutableArray *tempArr = [dic valueForKey:getterName];
        for (CCYKVOInfoModel *info in tempArr) {
            if (info && info.observer && [info.observer respondsToSelector:@selector(ccy_observerValueForKeyPath:object:change:context:)]) {
                NSMutableDictionary *change = [NSMutableDictionary dictionary];
                if (info.options & CCY_NSKeyValueObservingOptionNew && newValue) {
                    [change setValue:newValue forKey:@"new"];
                }
                
                if (info.options & CCY_NSKeyValueObservingOptionOld && oldValue) {
                    [change setValue:oldValue forKey:@"old"];
                }
                
                if (notificationIsPrior) {
                    if (info.options & CCY_NSKeyValueObservingOptionPrior) {
                        [change setValue:@"1" forKey:@"notificationIsPrior"];
                    } else {
                        continue;
                    }
                }
                
                //执行方法
                [info.observer ccy_observerValueForKeyPath:info.keyPath object:info.target change:change context:info.getContext];
            }
        }
    }
}

static void ccy_kvo_setter(id target, SEL sel, id p0) {
    //拿到调用父类方法之前的值
    NSString *getterName = getterNameFromSetterName(NSStringFromSelector(sel));
    id old = [target valueForKey:getterName];
    callBack(target, nil, old, getterName, YES);
    
    //给父类发送消息
    struct objc_super sup = {
        .receiver = target,
        .super_class = class_getSuperclass(object_getClass(target))
    };
    
    ((void(*)(struct objc_super *, SEL, id)) objc_msgSendSuper)(&sup, sel, p0);
    
    //回调
    callBack(target, p0, old, getterName, NO);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NSObject (CCYKVO)
#pragma clang diagnostic pop

- (void)ccy_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(CCY_NSKeyValueObservingOptions)options context:(void *)context {
    if (!observer || ! keyPath) return;
    
    @synchronized(self) {
        //给keypath 链条最终类偶逻辑
        NSArray *keyArr = [keyPath componentsSeparatedByString:@"."];
        if (keyArr.count <= 0) return;
        id nextTarget = self;
        
        for (int i = 0; i < keyArr.count - 1; i++) {
            nextTarget = [nextTarget valueForKey:keyArr[i]];
        }
        
        if (![self ccy_coreLogicWithTarget:nextTarget getterName:keyArr.lastObject]) {
            return;
        }
        
        //给目标绑定信息
        CCYKVOInfoModel *info = [CCYKVOInfoModel new];
        info.target = self;
        info.observer = observer;
        info.keyPath = keyPath;
        info.options = options;
        [info setContext:context];
        [self ccy_bindInfoToTarget:nextTarget info:info key:keyArr.lastObject options:options];
    }
}

- (void)ccy_bindInfoToTarget:(id)target info:(CCYKVOInfoModel *)info key:(NSString *)key options:(CCY_NSKeyValueObservingOptions)options {
    NSMutableDictionary *dic = objc_getAssociatedObject(target, keyOfCCYKVOInfoModel);
    if (dic) {
        if ([dic valueForKey:key]) {
            NSMutableArray *tempArr = [dic valueForKey:key];
            [tempArr addObject:info];
        } else {
            NSMutableArray *tempArr = [NSMutableArray array];
            [tempArr addObject:info];
            [dic setObject:tempArr forKey:key];
        }
    } else {
        NSMutableDictionary *addDic = [NSMutableDictionary dictionary];
        NSMutableArray *tempArr = [NSMutableArray array];
        [tempArr addObject:info];
        [addDic setObject:tempArr forKey:key];
        objc_setAssociatedObject(target, keyOfCCYKVOInfoModel, addDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (options & CCY_NSKeyValueObservingOptionInitial) {
        callBack(target, nil, nil, key, NO);
    }
}

- (BOOL)ccy_coreLogicWithTarget:(id)target getterName:(NSString *)getterName {
    //若setter不存在
    NSString *setterName = setterNameFromGetterName(getterName);
    SEL setterSel = NSSelectorFromString(setterName);
    Method setterMethod = class_getInstanceMethod(object_getClass(target), setterSel);
    if (!setterMethod) return NO;
    
    //创建派生类并且更改isa指针
    [self ccy_createSubClassWithTarget:target];
    
    //给派生类添加setter方法体
    if (!classHasSel(object_getClass(target), setterSel)) {
        const char *types = method_getTypeEncoding(setterMethod);
        return class_addMethod(object_getClass(target), setterSel, (IMP)ccy_kvo_setter, types);
    }
    return YES;
    
}

- (void)ccy_createSubClassWithTarget:(id)target {
    
    //若isa只想是否已经是派生类
    Class nowClass = object_getClass(target);
    NSString *nowClass_name = NSStringFromClass(nowClass);
    if ([nowClass_name hasPrefix:kPrefixOfCCYKVO]) {
        return;
    }
    
    //若派生类存在
    NSString *subClass_name = [kPrefixOfCCYKVO stringByAppendingString:nowClass_name];
    Class subClass = NSClassFromString(subClass_name);
    if (subClass) {
        //将该对象 isa指针只想派生类
        object_setClass(target, subClass);
        return;
    }
    
    //添加派生类
    subClass = objc_allocateClassPair(nowClass, subClass_name.UTF8String, 0);
    const char *types = method_getTypeEncoding(class_getInstanceMethod(nowClass, @selector(class)));
    IMP class_imp = imp_implementationWithBlock(^Class(id target){
        return class_getSuperclass(object_getClass(target));
    });
    
    class_addMethod(subClass, @selector(class), class_imp, types);
    
    //将该对象isa指针指向派生类
    object_setClass(target, subClass);
}


#pragma mark - remove
- (void)ccy_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    [self ccy_removeObserver:observer forKeyPath:keyPath context:nil];
}

- (void)ccy_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    @synchronized(self) {
        //移除配置信息
        NSArray *keyArr = [keyPath componentsSeparatedByString:@"."];
        if (keyArr.count <= 0) return;
        id nextTarget = self;
        for (int i = 0; i < keyArr.count - 1; i++) {
            nextTarget = [nextTarget valueForKey:keyArr[i]];
        }
        NSString *getterName = keyArr.lastObject;
        NSMutableDictionary *dic = objc_getAssociatedObject(nextTarget, keyOfCCYKVOInfoModel);
        if (dic && [dic valueForKey:getterName]) {
            NSMutableArray *tempArray = [dic valueForKey:getterName];
            @autoreleasepool {
                for (CCYKVOInfoModel *info in tempArray.copy) {
                    if (info.getContext == context) {
                        [tempArray removeObject:info];
                    }
                }
            }
            if (tempArray.count == 0) {
                [dic removeObjectForKey:getterName];
            }
            
            //若无可监听项，isa指针指回去
            if (dic.count <= 0) {
                Class nowClass = object_getClass(nextTarget);
                NSString *nowClass_name = NSStringFromClass(nowClass);
                if ([nowClass_name hasPrefix:kPrefixOfCCYKVO]) {
                    Class superClass = [nextTarget class];
                    object_setClass(nextTarget, superClass);
                }
            }
        }
    }
}

@end
