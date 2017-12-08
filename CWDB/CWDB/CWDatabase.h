//
//  CWDatabase.h
//  CWDB
//
//  Created by ChavezChen on 2017/12/2.
//  Copyright © 2017年 Chavez. All rights reserved.
// 数据库类，主要用于调用苹果原生的Sqlite API操作数据库

#import <Foundation/Foundation.h>

@interface CWDatabase : NSObject

// 执行语句
+ (BOOL)execSQL:(NSString *)sql uid:(NSString *)uid;

// 查询语句
+ (NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid;

+ (BOOL)openDB:(NSString *)uid;

@end
