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

#pragma mark - 格式化字段数据，我们的宗旨：一切不可识别的对象，都转字符串
+ (id)formatModelValue:(id)value type:(NSString *)type isEncode:(BOOL)isEncode{
    
    if (isEncode && value == nil) { // 只有对象才能为nil，基本数据类型没值时为0
        return @"";
    }
    if (!isEncode && [value isKindOfClass:[NSString class]] && [value isEqualToString:@""]) {
        return [NSClassFromString(type) new];
    }
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]||
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]||
       [value isKindOfClass:[NSNumber class]]) {
        return value;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return value;
    }else if ([type containsString:@"NSData"]) {
        if (isEncode) {
            return [value base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else {
            return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
    }else if ([type isEqualToString:@"UIImage"]) {
        if (isEncode) {
            NSData* data = UIImageJPEGRepresentation(value, 1);
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else {
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    } else if ([type containsString:@"String"]) {
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
    }else if ([type containsString:@"Dictionary"] && [type containsString:@"NS"]) {
        if (isEncode) {
            return [self stringWithDict:value];
        }else {
            return [self dictWithString:value type:type];
        }
        
    }else if (([type containsString:@"Array"] || [type containsString:@"Set"]) && [type containsString:@"NS"] ) {
        if (isEncode) {
            return [self stringWithArray:value];
        }else {
            return [self arrayWithString:value type:type];
        }
    }else if ([type containsString:@"UIColor"]){
        if(isEncode){
            CGFloat r, g, b, a;
            [value getRed:&r green:&g blue:&b alpha:&a];
            return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
        }else{
            NSArray<NSString*>* arr = [value componentsSeparatedByString:@","];
            return [UIColor colorWithRed:arr[0].floatValue green:arr[1].floatValue blue:arr[2].floatValue alpha:arr[3].floatValue];
        }
    }else if ([type containsString:@"NSURL"]){
        if(isEncode){
            return [value absoluteString];
        }else{
            return [NSURL URLWithString:value];
        }
    }else if ([type containsString:@"NSRange"]){
        if(isEncode){
            return NSStringFromRange([value rangeValue]);
        }else{
            return [NSValue valueWithRange:NSRangeFromString(value)];
        }
    }else { // 当模型处理
        if (isEncode) {  // 模型转json字符串
            NSDictionary *modelDict = [self dictWithModel:value];
            return [self stringWithDict:modelDict];
        }else {  // 字符串转模型
            NSDictionary *dict = [self dictWithString:value type:type];
            return [self model:NSClassFromString(type) Dict:dict];
        }
    }
    return @"";
}

#pragma mark - NSDate<-->字符串
+ (NSString *)stringWithDate:(NSDate *)date {
    NSDateFormatter* formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:date];
}

+ (NSDate *)dateWithString:(NSString *)str {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [formatter dateFromString:str];
    return date;
}

#pragma mark - 集合类型转JSON字符串
// 数组转字符串
+ (NSString *)stringWithArray:(id)array {
    
    if ([NSJSONSerialization isValidJSONObject:array]) {
        // array -> Data
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        NSMutableArray *arrayM = [NSMutableArray array];
        for (id value in array) {
            
            id result = [self formatModelValue:value type:NSStringFromClass([value class]) isEncode:YES];
            NSDictionary *dict = @{NSStringFromClass([value class]) : result};
            [arrayM addObject:dict];
        }
        return [[self stringWithArray:arrayM] stringByAppendingString:@"CWCustomCollection"];
    }
}

// 字典转字符串
+ (NSString *)stringWithDict:(NSDictionary *)dict {
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        // dict -> data
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        
        NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
        for (NSString *key in dict.allKeys) {
            id value = dict[key];
            id result = [self formatModelValue:value type:NSStringFromClass([value class]) isEncode:YES];
            NSDictionary *valueDict = @{NSStringFromClass([value class]) : result};
            [dictM setValue:valueDict forKey:key];
        }
        return [[self stringWithDict:dictM] stringByAppendingString:@"CWCustomCollection"];
    }
}

#pragma mark - JSON字符串转集合类型
// 字符串转数组(还原)
+ (id)arrayWithString:(NSString *)str type:(NSString *)type{
    if ([str hasSuffix:@"CWCustomCollection"]) {
        NSUInteger length = @"CWCustomCollection".length;
        str = [str substringToIndex:str.length - length];
        NSJSONReadingOptions options = kNilOptions; // 是否可变
        if ([type containsString:@"Mutable"] || [type containsString:@"NSArrayM"]) {
            options = NSJSONReadingMutableContainers;
        }
        NSMutableArray *resultArr = [NSMutableArray array];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        id result = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
        id value;
        for (NSDictionary *dict in result) {
            value = [self formatModelValue:dict.allValues.firstObject type:dict.allKeys.firstObject isEncode:NO];
            [resultArr addObject:value];
        }
        if (options == kNilOptions) {
            resultArr = [resultArr copy]; // 不可变数组
        }
        return resultArr;
    }else {
        return [self formatJsonArrayAndJsonDict:str type:type];
    }
    
}
// 字符串转字典(还原)
+ (id)dictWithString:(NSString *)str type:(NSString *)type {
    if ([str hasSuffix:@"CWCustomCollection"]) {
        NSUInteger length = @"CWCustomCollection".length;
        str = [str substringToIndex:str.length - length];
        NSJSONReadingOptions options = kNilOptions; // 是否可变
        if ([type containsString:@"Mutable"] || [type containsString:@"NSDictionaryM"]) {
            options = NSJSONReadingMutableContainers;
        }
        NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        id resultDict = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
        
        for (NSString *key in [resultDict allKeys]) {
            NSDictionary *valueDict = [resultDict valueForKey:key];
            id value = valueDict.allValues.firstObject;
            NSString *type = valueDict.allKeys.firstObject;
            id resultValue = [self formatModelValue:value type:type isEncode:NO];
            [dictM setValue:resultValue forKey:key];
            
        }
        return dictM;
    }else {
        return [self formatJsonArrayAndJsonDict:str type:type];
    }
    
}

// json数组和json字典可直接转换
+ (id)formatJsonArrayAndJsonDict:(NSString *)str type:(NSString *)type {
    NSJSONReadingOptions options = kNilOptions;
    if ([type containsString:@"Mutable"] || [type containsString:@"NSArrayM"] || [type containsString:@"NSDictionaryM"]) {
        options = NSJSONReadingMutableContainers;
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    id result = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
    
    return result;
}

#pragma mark - 模型转字典
+ (NSDictionary *)dictWithModel:(id)model {
    // 获取类的所有成员变量的名称与类型
    NSDictionary *nameTypeDict = [CWModelTool classIvarNameAndTypeDic:[model class]];
    // 获取模型所有成员变量
    NSArray *allIvarNames = nameTypeDict.allKeys;
    
    NSMutableDictionary *allIvarValues = [NSMutableDictionary dictionary];
    // 获取所有成员变量对应的值
    for (NSString *ivarName in allIvarNames) {
        id value = [model valueForKeyPath:ivarName];
        NSString *type = nameTypeDict[ivarName];
        
        value = [CWModelTool formatModelValue:value type:type isEncode:YES];
        allIvarValues[ivarName] = value;
    }
    return allIvarValues;
}

#pragma mark - 字典转模型
+ (id)model:(Class)cls Dict:(NSDictionary *)dict {
    id model = [cls new];
    // 获取所有属性名
    NSArray *ivarNames = [CWModelTool allIvarNames:cls];
    // 获取所有属性名和类型的字典 {ivarName : type}
    NSDictionary *nameTypeDict = [CWModelTool classIvarNameAndTypeDic:cls];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id value = obj;
        // 判断数据库查询到的key 在当前模型中是否存在，存在才赋值
        if ([ivarNames containsObject:key]) {
            
            NSString *type = nameTypeDict[key];
            
            value = [CWModelTool formatModelValue:value type:type isEncode:NO];
            if (value == nil) {
                value = @(0);
            }
            [model setValue:value forKeyPath:key];
        }
    }];
    
    return model;
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



