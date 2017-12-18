//
//  CWModelTool.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//  模型的工具类，解析模型的所有成员变量

#import <Foundation/Foundation.h>

@interface CWModelTool : NSObject


/**
 获取模型对应的数据库表名

 @param cls 模型类型
 @param targetId 目标id，同样的模型要对应不同的目标对象（不同的数据库表）存储，需要这个字段识别,例如聊天的聊天记录，同样的消息模型，需要分聊天对象存储。不需要区分的时候传nil即可
 @return 数据库表名
 */
+ (NSString *)tableName:(Class)cls targetId:(NSString *)targetId;

+ (NSString *)tmpTableName:(Class)cls targetId:(NSString *)targetId;



/**
 获取模型所有成员变量的类型以及名称 {名称 ：类型}

 @param cls 模型类型
 @return 模型所有成员变量的类型以及名称组成的字典 例如 int stuId --> { stuId : int }
 */
+ (NSDictionary *)classIvarNameAndTypeDic:(Class)cls;


/**
 将模型的所有成员变量的类型以及名称转换成sql语句可用的字符串

 @param cls 模型类型
 @return 拼接成的字符串 例如 int a ； int b； --> a i，b i
 */
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

@end


// 缓存模型语句
@interface CWCache : NSCache

+ (instancetype)shareInstance;

@end


