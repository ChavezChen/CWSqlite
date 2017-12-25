//
//  CWSqliteTableTool.h
//  CWDB
//
//  Created by mac on 2017/12/7.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWSqliteTableTool : NSObject

// 表格是否存在
+ (BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid;

// 获取数据库表格的所有字段
+ (NSArray *)allTableColumnNames:(NSString *)tableName uid:(NSString *)uid;

// 数据库表是否需要更新
+ (BOOL)isTableNeedUpdate:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;



@end
