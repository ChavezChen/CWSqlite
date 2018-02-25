//
//  CWModelTool.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//  模型的工具类，解析模型的所有成员变量

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CWModelTool : NSObject

 // 获取模型对应的数据库表名
+ (NSString *)tableName:(Class)cls targetId:(NSString *)targetId;
// 获取临时表名
+ (NSString *)tmpTableName:(Class)cls targetId:(NSString *)targetId;

// 获取类所有成员变量的类型以及名称组成的字典 例如 int stuId --> { stuId : int }
+ (NSDictionary *)classIvarNameAndTypeDic:(Class)cls;
 // 将模型的所有成员变量的类型以及名称转换成sql语句可用的字符串 例如 int a ； int b； --> a i，b i
+ (NSString *)sqlColumnNamesAndTypesStr:(Class)cls;

// 返回模型的所有成员变量
+ (NSArray *)allIvarNames:(Class)cls;

// 格式化模型的value或将数据库内的数据转换到模型对应的类型的值，我们的口号：一切不是数据库支持格式的数据，通通都转成字符串
+ (id)formatModelValue:(id)value type:(NSString *)type isEncode:(BOOL)isEncode;


// 模型转字典
+ (NSDictionary *)dictWithModel:(id)model;

// 字典转模型
+ (id)model:(Class)cls Dict:(NSDictionary *)dict;

// 字典转字符串
+ (NSString *)stringWithDict:(id)dict;

// 字符串转字典
+ (id)dictWithString:(NSString *)str type:(NSString *)type;

// 数组转字典
+ (NSString *)stringWithArray:(id)array;

// 字符串转数组
+ (id)arrayWithString:(NSString *)str type:(NSString *)type;

@end


// 缓存模型语句
@interface CWCache : NSCache

+ (instancetype)shareInstance;

@end


