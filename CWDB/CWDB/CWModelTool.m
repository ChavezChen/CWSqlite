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

+ (id)formatModelValue:(id)value type:(NSString *)type isEncode:(BOOL)isEncode{
    
    if (!isEncode && [value isKindOfClass:[NSString class]] && [value isEqualToString:@""]) {
        return [NSClassFromString(type) new];
    }
    
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return value;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return value;
    }else if ([type containsString:@"Data"]) {
        return value;
    }else if ([type containsString:@"String"]) {
        if ([type containsString:@"AttributedString"]) {
            if (isEncode) {
                NSData *data = [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
                return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }else {
                NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
        return value;
    }else if ([type containsString:@"Dictionary"]) {
        if (isEncode) {
            return [self stringWithDict:value];
        }else {
            return [self dictWithString:value type:type];
        }
        
    }else if ([type containsString:@"Array"]) {
        if (isEncode) {
            return [self stringWithArray:value];
        }else {
            return [self arrayWithString:value type:type];
        }
        
    }
    
    return @"";
}
#pragma mark 模型类型转数据库类型字符串
// 数组转字符串
+ (NSString *)stringWithArray:(id)array {
    
    if ([NSJSONSerialization isValidJSONObject:array]) {
        // array -> Data
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        return nil;
    }
}

// 字段转字符串
+ (NSString *)stringWithDict:(id)dict {
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        // dict -> data
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        return nil;
    }
}

#pragma mark 数据库类型字符串转模型类型
// 字符串转数组
+ (id)arrayWithString:(NSString *)str type:(NSString *)type{
    return [self formatJsonArrayAndJsonDict:str type:type];
}
// 字符串转字典
+ (id)dictWithString:(NSString *)str type:(NSString *)type {
    return [self formatJsonArrayAndJsonDict:str type:type];
}

// json数组和json字典可直接转换
+ (id)formatJsonArrayAndJsonDict:(NSString *)str type:(NSString *)type {
    id result;
    if ([type containsString:@"Mutable"]) {
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        //NSJSONReadingMutableContainers 可变
        result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    }else {
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        //kNilOptions 不可变
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    return result;
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



