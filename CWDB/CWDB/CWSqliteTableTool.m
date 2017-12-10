//
//  CWSqliteTableTool.m
//  CWDB
//
//  Created by mac on 2017/12/7.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWSqliteTableTool.h"
#import "CWDatabase.h"

@implementation CWSqliteTableTool

+ (BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid{
    // 去sqlite_master这个表里面去查询是否存在这个表
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'",tableName];
    
    NSMutableArray *resultArray = [CWDatabase querySql:queryCreateSqlStr uid:uid];
    return resultArray.count > 0;
}


@end
