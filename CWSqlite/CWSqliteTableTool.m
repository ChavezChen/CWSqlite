//
//  CWSqliteTableTool.m
//  CWDB
//
//  Created by mac on 2017/12/7.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWSqliteTableTool.h"
#import "CWDatabase.h"
#import "CWModelTool.h"
#import "CWModelProtocol.h"

@implementation CWSqliteTableTool

+ (BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid{
    // 去sqlite_master这个表里面去查询创建此索引的sql语句
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'",tableName];
    
    NSMutableArray *resultArray = [CWDatabase querySql:queryCreateSqlStr uid:uid];
    return resultArray.count > 0;
}

// 获取表的所有字段名，排序后返回
+ (NSArray *)allTableColumnNames:(NSString *)tableName uid:(NSString *)uid {
    
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'",tableName];
    NSArray *dictArr = [CWDatabase querySql:queryCreateSqlStr uid:uid];
    NSMutableDictionary *dict = dictArr.firstObject;
//    NSLog(@"---------------%@",dict);
    NSString *createSql = dict[@"sql"];
    if (createSql.length == 0) {
        return nil;
    }
    // sql = "CREATE TABLE Student(age integer,stuId integer,score real,height integer,name text, primary key(stuId))";
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    NSString *nameTypeStr = [createSql componentsSeparatedByString:@"("][1];
    NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];
    
    NSMutableArray *names = [NSMutableArray array];
    
    for (NSString *nameType in nameTypeArray) {
        // 去掉主键
        if ([nameType containsString:@"primary"]) {
            continue;
        }
        // 压缩掉字符串里面的 @“ ”  只压缩两端的
        NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
        // age integer
        NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
        [names addObject:name];
    }
    
    [names sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return names;
}

// 数据库表是否需要更新
+ (BOOL)isTableNeedUpdate:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {

    NSArray *modelNames = [CWModelTool allIvarNames:cls];
    
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSArray *tableNames = [self allTableColumnNames:tableName uid:uid];
    
    return ![modelNames isEqualToArray:tableNames];
}



@end
