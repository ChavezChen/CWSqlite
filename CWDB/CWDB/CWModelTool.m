//
//  CWModelTool.m
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWModelTool.h"
#import "CWModelProtocol.h"
#import <objc/runtime.h>

@implementation CWModelTool

+ (NSString *)tableName:(Class)cls targetId:(NSString *)targetId {
    if (!targetId) targetId = @"";
    return [NSString stringWithFormat:@"%@%@",NSStringFromClass(cls),targetId];
}

+ (NSString *)tmpTableName:(Class)cls targetId:(NSString *)targetId {
    if (!targetId) targetId = @"";
    return [NSString stringWithFormat:@"%@_tmp",[self tableName:cls targetId:targetId]];
}


+ (NSDictionary *)classIvarNameAndTypeDic:(Class)cls {
    NSDictionary *cacheIvarNameAndTypeDic = [[CWCache shareInstance] objectForKey:NSStringFromClass(cls)];
    if (cacheIvarNameAndTypeDic) {
        return cacheIvarNameAndTypeDic;
    }
    unsigned int outCount = 0;
    Ivar *varList = class_copyIvarList(cls, &outCount);
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    
    NSArray *ignoreNames = nil;
    if ([cls respondsToSelector:@selector(ignoreColumnNames)]) {
        ignoreNames = [cls ignoreColumnNames];
    }
    
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = varList[i];
        // 1.获取成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        
        // 忽略字段
        if ([ignoreNames containsObject:ivarName]) {
            continue;
        }
        
        // 2.获取成员变量类型 @\"
        NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        
        [nameTypeDic setValue:type forKey:ivarName];
        
    }
    [[CWCache shareInstance] setObject:nameTypeDic forKey:NSStringFromClass(cls)];
    return nameTypeDic;
}

+ (NSDictionary *)classIvarNameAndSqlTypeDic:(Class)cls {
    // 获取模型的所有成员变量
    NSMutableDictionary *classDict = [[self classIvarNameAndTypeDic:cls] mutableCopy];
    
    [classDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        // 对应的数据库的类型重新赋值
        classDict[key] = [self getSqlType:obj];
    }];
    return classDict;
}

+ (NSString*)getSqlType:(NSString*)type{
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return @"integer";
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return @"real";
    }else if ([type isEqualToString:@"NSData"]) {
        return @"blob";
    }else{
        return @"text";
    }
}

+ (NSString *)sqlColumnNamesAndTypesStr:(Class)cls {
    // 缓存
    NSDictionary *sqlDict = [[self classIvarNameAndSqlTypeDic:cls] mutableCopy];
    NSMutableArray *nameTypeArr = [NSMutableArray array];

    [sqlDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        [nameTypeArr addObject:[NSString stringWithFormat:@"%@ %@",key,obj]];
    }];
    
    return [nameTypeArr componentsJoinedByString:@","];
}

+ (NSArray *)allIvarNames:(Class)cls {
    NSDictionary *dict = [self classIvarNameAndTypeDic:cls];
    NSArray *names = dict.allKeys;
    // 排序
    names = [names sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return names;
}



@end

@implementation CWCache

static CWCache *cw_cache = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cw_cache = [[CWCache alloc] init];
    });
    return cw_cache;
}


@end



