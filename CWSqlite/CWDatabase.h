//
//  CWDatabase.h
//  CWDB
//
//  Created by ChavezChen on 2017/12/2.
//  Copyright © 2017年 Chavez. All rights reserved.
// 数据库类，主要用于调用苹果原生的Sqlite API操作数据库

#import <Foundation/Foundation.h>

@interface CWDatabase : NSObject

// 打开数据库
+ (BOOL)openDB:(NSString *)uid;
// 关闭数据库
+ (void)closeDB;
// 执行语句
+ (BOOL)execSQL:(NSString *)sql uid:(NSString *)uid;
// 查询语句
+ (NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid;
// 执行多个sql语句
+ (BOOL)execSqls:(NSArray <NSString *>*)sqls uid:(NSString *)uid;

#pragma mark - 事务
// 开始事务
+ (void)beginTransaction:(NSString *)uid;
// 提交事务
+ (void)commitTransaction:(NSString *)uid;
// 回滚事务
+ (void)rollBackTransaction:(NSString *)uid;


@end
