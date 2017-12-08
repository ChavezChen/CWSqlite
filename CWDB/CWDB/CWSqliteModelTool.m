//
//  CWSqliteModelTool.m
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWSqliteModelTool.h"
#import "CWModelTool.h"
#import "CWDatabase.h"

@implementation CWSqliteModelTool

+ (BOOL)createSQLTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {
    // 创建数据库表的语句
    // create table if not exists 表名(字段1 字段1类型（约束）,字段2 字段2类型（约束）....., primary key(字段))
    // 获取数据库表名
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        return NO;
    }
    // 获取主键
    NSString *primaryKey = [cls primaryKey];
    if (!primaryKey) {
        NSLog(@"你需要指定一个主键来创建数据库表");
        return NO;
    }
    
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))",tableName,[CWModelTool sqlColumnNamesAndTypesStr:cls],primaryKey];
    
    return [CWDatabase execSQL:createTableSql uid:uid];
}

+ (BOOL)insertModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    Class cls = [model class];
    // 判断数据库内是否有对应表格,没有则创建
    
    
    return YES;
}






@end
