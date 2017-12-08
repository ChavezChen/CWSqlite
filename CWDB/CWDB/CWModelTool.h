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



@end


// 缓存模型语句
@interface CWCache : NSCache

+ (instancetype)shareInstance;

@end


