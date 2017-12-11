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

// 更新表并迁移数据
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId{
    
    // 1.创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [CWModelTool tmpTableName:cls targetId:targetId];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    // 类方法可以直接响应 对象方法[cls new] responds...
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        return NO;
    }
    
    // 保存所有需要执行的sql语句
    NSMutableArray *execSqls = [NSMutableArray array];
    
    NSString *primaryKey = [cls primaryKey];
    // 1.2 获取一个模型里面所有的字段，以及类型
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))",tmpTableName,[CWModelTool sqlColumnNamesAndTypesStr:cls],primaryKey];
    
    [execSqls addObject:createTableSql];
    
    // 2.根据主键插入数据
    //--insert into cwstu_tmp(stuNum) select stuNum from CWStu;
    NSString *inserPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@",tmpTableName,primaryKey,primaryKey,tableName];
    
    [execSqls addObject:inserPrimaryKeyData];
    
    // 3.根据主键，把所有的数据插入到怕新表里面去
    NSArray *oldNames = [self allTableColumnNames:tableName uid:uid];
    NSArray *newNames = [CWModelTool allIvarNames:cls];
    
    // 4.获取更名字典
    NSDictionary *newNameToOldNameDic = @{};
    if ([cls respondsToSelector:@selector(newNameToOldNameDic)]) {
        newNameToOldNameDic = [cls newNameToOldNameDic];
    }
    
    for (NSString *columnName in newNames) {
        NSString *oldName = columnName;
        // 找映射的旧的字段名称
        if ([newNameToOldNameDic[columnName] length] != 0) {
            oldName = newNameToOldNameDic[columnName];
        }
        // 如果老表包含了新的列名，应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && [columnName isEqualToString:oldName]) || [oldNames containsObject:primaryKey]) {
            continue;
        }
        // --update cwstu_tmp set name = (select name from cwstu where cwstu_tmp.stuNum = cwstu.stuNum);
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@)",tmpTableName,columnName,oldName,tableName,tmpTableName,primaryKey,tableName,primaryKey];
        
        [execSqls addObject:updateSql];
        
    }
    
    
    NSString *deleteOldTable = [NSString stringWithFormat:@"drop table if exists %@",tableName];
    [execSqls addObject:deleteOldTable];
    
    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@",tmpTableName,tableName];
    [execSqls addObject:renameTableName];
    
    return [CWDatabase execSqls:execSqls uid:uid];
    
}

@end
