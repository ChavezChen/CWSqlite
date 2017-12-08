//
//  CWSqliteModelTool.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//  数据库模型工具类,主要通过调用这个工具的API实现操作数据库

#import <Foundation/Foundation.h>
#import "CWModelProtocol.h"

@interface CWSqliteModelTool : NSObject

/**
 创建数据库表

 @param cls 模型类型
 @param uid 用户userid，用于数据库名称
 @param targetId 目标id，用于数据库表名称  表的名称为:className+targetId
 @return 创建成功或失败
 */
+ (BOOL)createSQLTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;


+ (BOOL)insertModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;


@end
