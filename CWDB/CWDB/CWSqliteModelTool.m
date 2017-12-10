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
#import "CWSqliteTableTool.h"

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

#pragma mark 插入数据
+ (BOOL)insertModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    // 获取表名
    Class cls = [model class];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    // 1.判断数据库内是否有对应表格,没有则创建(这一步先不做，因为我们目前还没有实现查询语句,我们先在外面创建一个表格，再执行插入操作)
    
    // 2.插入数据
    // 获取类的所有成员变量的名称与类型
    NSDictionary *nameTypeDict = [CWModelTool classIvarNameAndTypeDic:cls];
    // 获取所有成员变量的名称，也就是sql语句字段名称
    NSArray *allIvarNames = nameTypeDict.allKeys;
    // 获取所有成员变量对应的值
    NSMutableArray *allIvarValues = [NSMutableArray array];
    for (NSString *ivarName in allIvarNames) {
        // 获取对应的值,暂时不考虑自定义模型和oc模型的情况
        id value = [model valueForKeyPath:ivarName];
        [allIvarValues addObject:value];
    }
    
    // insert into 表名(字段1，字段2，字段3) values ('值1'，'值2'，'值3')
    NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')",tableName,[allIvarNames componentsJoinedByString:@","],[allIvarValues componentsJoinedByString:@"','"]];
    
    return [CWDatabase execSQL:sql uid:uid];
}

#pragma mark 查询数据
// 查询表内所有数据
+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {
    
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    return [self parseResults:results withClass:cls];
}
// 解析数组
+ (NSArray *)parseResults:(NSArray <NSDictionary *>*)results withClass:(Class)cls  {
    
    NSMutableArray *models = [NSMutableArray array];
    
    for (NSDictionary *dict in results) {
        id model = [[cls alloc] init];
        
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id value = obj;
            [model setValue:value forKeyPath:key];
        }];
        
        [models addObject:model];
    }
    
    return models;
}

#pragma mark 插入或者更新数据
+ (BOOL)insertOrUpdateModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    // 获取表名
    Class cls = [model class];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    // 判断数据库是否存在对应的表，不存在则创建
    if (![CWSqliteTableTool isTableExists:tableName uid:uid]) {
        [self createSQLTable:cls uid:uid targetId:targetId];
    }
    
    // 根据主键，判断数据库内是否存在记录
    // 判断对象是否返回主键信息
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
    // 模型中的主键的值
    id primaryValue = [model valueForKeyPath:primaryKey];
    //  查询语句：  NSString *checkSql = @"select * from 表名 where 主键 = '主键值' ";
    NSString * checkSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'",tableName,primaryKey,primaryValue];
    
    // 执行查询语句,获取结果
    NSArray *result = [CWDatabase querySql:checkSql uid:uid];
    // 获取类的所有成员变量的名称与类型
    NSDictionary *nameTypeDict = [CWModelTool classIvarNameAndTypeDic:cls];
    // 获取所有成员变量的名称，也就是sql语句字段名称
    NSArray *allIvarNames = nameTypeDict.allKeys;
    // 获取所有成员变量对应的值
    NSMutableArray *allIvarValues = [NSMutableArray array];
    for (NSString *ivarName in allIvarNames) {
        // 获取对应的值,暂时不考虑自定义模型和oc模型的情况
        id value = [model valueForKeyPath:ivarName];
        [allIvarValues addObject:value];
    }
    // 字段1=字段1值 allIvarNames[i]=allIvarValues[i]
    NSMutableArray *ivarNameValueArray = [NSMutableArray array];
    NSInteger count = allIvarNames.count;
    for (int i = 0; i < count; i++) {
        NSString *name = allIvarNames[i];
        id value = allIvarValues[i];
        NSString *ivarNameValue = [NSString stringWithFormat:@"%@='%@'",name,value];
        [ivarNameValueArray addObject:ivarNameValue];
    }
    
    NSString *execSql = @"";
    if (result.count > 0) { // 表内存在记录，更新
        // update 表名 set 字段1='字段1值'，字段2='字段2的值'...where 主键 = '主键值'
        execSql = [NSString stringWithFormat:@"update %@ set %@ where %@ = '%@'",tableName,[ivarNameValueArray componentsJoinedByString:@","],primaryKey,primaryValue];
    }else { // 表内不存在记录，插入
        // insert into 表名(字段1，字段2，字段3) values ('值1'，'值2'，'值3')
        execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')",tableName,[allIvarNames componentsJoinedByString:@","],[allIvarValues componentsJoinedByString:@"','"]];
    }
    return [CWDatabase execSQL:execSql uid:uid];
}

@end
