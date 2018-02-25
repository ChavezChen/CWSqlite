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

@interface CWSqliteModelTool ()

@property (nonatomic,strong)dispatch_semaphore_t dsema;

@end

@implementation CWSqliteModelTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dsema = dispatch_semaphore_create(1);
    }
    return self;
}

static CWSqliteModelTool * instance = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CWSqliteModelTool alloc] init];
    });
    return instance;
}


#pragma mark - 创建数据库表格
// 不需要自己调用
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
    // 执行语句
    BOOL result = [CWDatabase execSQL:createTableSql uid:uid];
    
    return result;
}


#pragma mark - 插入或者更新数据

#pragma mark 简易方法

+ (BOOL)insertOrUpdateModel:(id)model {
    return [self insertOrUpdateModels:@[model] uid:nil targetId:nil];
}

+ (BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray {
    return [self insertOrUpdateModels:modelsArray uid:nil targetId:nil];
}

#pragma mark 完整方法
// 插入单个模型
+ (BOOL)insertOrUpdateModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    return [self insertOrUpdateModels:@[model] uid:uid targetId:targetId];
}

// 批量插入或更新数据
+ (BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    id modelF = modelsArray.firstObject;
    // 获取表名
    Class cls = [modelF class];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    // 判断数据库是否存在对应的表，不存在则创建
    if (![CWSqliteTableTool isTableExists:tableName uid:uid]) {
        BOOL r = [self createSQLTable:cls uid:uid targetId:targetId];
        if (!r) {
            dispatch_semaphore_signal([[self shareInstance] dsema]);
            return NO;
        }
    }else { // 如果表格存在，则检测表格是否需要更新
        // 1、检查缓存，表格是否更新过,不考虑动态添加属性的情况下，只要更新更高一次即可
        if (!targetId) targetId = @"";
        NSString *cacheKey = [NSString stringWithFormat:@"%@%@CWUpdated",NSStringFromClass(cls),targetId];
        BOOL updated = [[[CWCache shareInstance] objectForKey:cacheKey] boolValue]; // 表格是否更新过
        if (!updated) { // 2、如果表格没有更新过,检测是否需要更新
            if ([CWSqliteTableTool isTableNeedUpdate:cls uid:uid targetId:targetId] ) {
                dispatch_semaphore_signal([[self shareInstance] dsema]);
                // 2.1、表格需要更新,则进行更新操作
                BOOL result = [self updateTable:cls uid:uid targetId:targetId];
                dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
                if (!result) {
                    // 2.2、更新失败，设置缓存为未更新
                    [[CWCache shareInstance] setObject:@(NO) forKey:cacheKey];
                    NSLog(@"更新数据库表结构失败!插入或更新数据失败!");
                    dispatch_semaphore_signal([[self shareInstance] dsema]);
                    return NO;
                }
                // 2.3、更新成功，设置缓存为已更新
                [[CWCache shareInstance] setObject:@(YES) forKey:cacheKey];
            }else {
                // 3、表格不需要更新,设置缓存为已更新
                [[CWCache shareInstance] setObject:@(YES) forKey:cacheKey];
            }
        }
    }
    
    // 根据主键，判断数据库内是否存在记录
    // 判断对象是否返回主键信息
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    // 获取主键
    NSString *primaryKey = [cls primaryKey];
    if (!primaryKey) {
        NSLog(@"你需要指定一个主键来创建数据库表");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    [CWDatabase beginTransaction:uid];
    for (id model in modelsArray) {
        @autoreleasepool {
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
            @autoreleasepool {
                // 获取对应的值,暂时不考虑自定义模型和oc模型的情况
                id value = [model valueForKeyPath:ivarName];
                
                NSString *type = nameTypeDict[ivarName];
                //        NSLog(@"type: %@ , value : %@ , valueClass : %@ , ivarName : %@",type,value,[value class],ivarName);
                
                value = [CWModelTool formatModelValue:value type:type isEncode:YES];
                
                [allIvarValues addObject:value];
            }
        }
        // 字段1=字段1值 allIvarNames[i]=allIvarValues[i]
        NSMutableArray *ivarNameValueArray = [NSMutableArray array];
        
        [allIvarNames enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *name = obj;
            id value = allIvarValues[idx];
            NSString *ivarNameValue = [NSString stringWithFormat:@"%@='%@'",name,value];
            [ivarNameValueArray addObject:ivarNameValue];
        }];
        
        NSString *execSql = @"";
        if (result.count > 0) { // 表内存在记录，更新
            // update 表名 set 字段1='字段1值'，字段2='字段2的值'...where 主键 = '主键值'
            execSql = [NSString stringWithFormat:@"update %@ set %@ where %@ = '%@'",tableName,[ivarNameValueArray componentsJoinedByString:@","],primaryKey,primaryValue];
        }else { // 表内不存在记录，插入
            // insert into 表名(字段1，字段2，字段3) values ('值1'，'值2'，'值3')
            execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')",tableName,[allIvarNames componentsJoinedByString:@","],[allIvarValues componentsJoinedByString:@"','"]];
        }
        // 执行数据库
        BOOL ret = [CWDatabase execSQL:execSql uid:uid];
        if (ret == NO) {
            [CWDatabase rollBackTransaction:uid];
            dispatch_semaphore_signal([[self shareInstance] dsema]);
            return NO;
        }
        }
    }
    // 提交事务
    [CWDatabase commitTransaction:uid];
    // 关闭数据库
    [CWDatabase closeDB];
    
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return YES;
}

#pragma mark - 查询数据

#pragma mark 简易方法

// 查询所有数据
+ (NSArray *)queryAllModels:(Class)cls {
    return [self queryAllModels:cls uid:nil targetId:nil];
}

// 单个条件查询
+ (NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(CWDBRelationType)relation value:(id)value {
    return [self queryModels:cls name:name relation:relation value:value uid:nil targetId:nil];
}

// 多个条件查询
+ (NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd {
    return [self queryModels:cls columnNames:columnNames relations:relations values:values isAnd:isAnd uid:nil targetId:nil];
}

// limit 分页查询
+ (NSArray *)queryModels:(Class)cls limit:(NSInteger)limit offset:(NSInteger)offset {
    return [self queryModels:cls limit:limit offset:offset uid:nil targetId:nil];
}

// 根据条件与排序 进行分页查询
+ (NSArray *)queryModels:(Class)cls cloumnName:(NSString *)columnName relation:(CWDBRelationType)relation value:(id)value orderName:(NSString *)orderName isDesc:(BOOL)isDesc limit:(NSInteger)limit offset:(NSInteger)offset {
    return [self queryModels:cls cloumnName:columnName relation:relation value:value orderName:orderName isDesc:isDesc limit:limit offset:offset uid:nil targetId:nil];
}

#pragma mark 完整方法

// 查询表内所有数据
+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return [self parseResults:results withClass:cls];
}

// 根据sql语句查询
+ (NSArray *)queryModels:(Class)cls Sql:(NSString *)sql uid:(NSString *)uid {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return [self parseResults:results withClass:cls];
}

// 根据单个条件查询
+ (NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(CWDBRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@'", tableName,name,self.CWDBNameToValueRelationTypeDic[@(relation)],value];
    
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return [self parseResults:results withClass:cls];
}

// 根据多个条件查询
+ (NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    if (!(columnNames.count == relations.count && relations.count == values.count)) {
        NSLog(@"columnNames、relations、values元素个数请保持一致!");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return nil;
    }
    
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *appendStr = isAnd ? @"and" : @"or" ;
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select * from %@ where",tableName];
    for (int i = 0; i < columnNames.count; i++) {
        NSString *columnName = columnNames[i];
        NSString *relation = self.CWDBNameToValueRelationTypeDic[relations[i]];
        id value = values[i];
        NSString *nameValueStr = [NSString stringWithFormat:@" %@ %@ '%@' ",columnName,relation,value];
        [sql appendString:nameValueStr];
        if (i != columnNames.count - 1) {
            [sql appendString:appendStr];
        }
    }
    
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return [self parseResults:results withClass:cls];
}


// limit 分页查询
+ (NSArray *)queryModels:(Class)cls limit:(NSInteger)limit offset:(NSInteger)offset uid:(NSString *)uid targetId:(NSString *)targetId {
    return [self queryModels:cls cloumnName:nil relation:0 value:nil orderName:nil isDesc:YES limit:limit offset:offset uid:uid targetId:targetId];
}

// 根据条件与排序 进行分页查询
+ (NSArray *)queryModels:(Class)cls cloumnName:(NSString *)columnName relation:(CWDBRelationType)relation value:(id)value orderName:(NSString *)orderName isDesc:(BOOL)isDesc limit:(NSInteger)limit offset:(NSInteger)offset uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSString *sortType = isDesc ? @"desc" : @"asc";
    NSString *whereSqliteStr = (columnName && value) ? [NSString stringWithFormat:@" where %@%@%@",columnName,self.CWDBNameToValueRelationTypeDic[@(relation)],value] : @"";
    NSString *orderSqliteStr = orderName ? [NSString stringWithFormat:@" order by %@ %@",orderName,sortType] : @"";
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *sql = [NSString stringWithFormat:@"select * from %@%@%@ limit %zd offset %zd", tableName,whereSqliteStr,orderSqliteStr,limit,offset];
    NSArray <NSDictionary *>*results = [CWDatabase querySql:sql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return [self parseResults:results withClass:cls];
}


// 解析数组                             {字段名称 : 值}
+ (NSArray *)parseResults:(NSArray <NSDictionary *>*)results withClass:(Class)cls  {
    
    NSMutableArray *models = [NSMutableArray array];
    // {字段名称 : 值}
    for (NSDictionary *dict in results) {
        
        id model = [CWModelTool model:cls Dict:dict];
        [models addObject:model];
    }
    return models;
}

#pragma mark - 删除数据

#pragma mark 简易方法

// 删除模型
+ (BOOL)deleteModel:(id)model {
    return [self deleteModel:model uid:nil targetId:nil];
}

// 删除数据表所有数据
+ (BOOL)deleteTableAllData:(Class)cls isKeepTable:(BOOL)isKeep {
    return [self deleteTableAllData:cls uid:nil targetId:nil isKeepTable:isKeep];
}

// 根据单个条件删除
+ (BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(CWDBRelationType)relation value:(id)value {
    return [self deleteModels:cls columnName:name relation:relation value:value uid:nil targetId:nil];
}

// 根据多个条件删除
+ (BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd {
    return [self deleteModels:cls columnNames:columnNames relations:relations values:values isAnd:isAnd uid:nil targetId:nil];
}

#pragma mark 完整方法
// 删除表中所有数据，或者干脆把表也一块删了
+ (BOOL)deleteTableAllData:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId isKeepTable:(BOOL)isKeep {
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *deleteSql ;
    if (isKeep) {
        deleteSql = [NSString stringWithFormat:@"delete from %@",tableName];
    }else {
        deleteSql = [NSString stringWithFormat:@"drop table if exists %@",tableName];
    }
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    // 执行数据库
    BOOL result = [CWDatabase execSQL:deleteSql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

// 根据模型的主键来删除
+ (BOOL)deleteModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    Class cls = [model class];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'",tableName,primaryKey,primaryValue];
    
    // 执行数据库
    BOOL result = [CWDatabase execSQL:deleteSql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

// 自己写sql语句删除
+ (BOOL)deleteModelWithSql:(NSString *)deleteSql uid:(NSString *)uid{
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    
    BOOL result = [CWDatabase execSQL:deleteSql uid:uid];
    
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return result;
}

// 根据单个条件删除
+ (BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(CWDBRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId {
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ %@ '%@'",tableName,name,self.CWDBNameToValueRelationTypeDic[@(relation)],value];
    
    BOOL result = [CWDatabase execSQL:deleteSql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

// 根据多个条件删除
+ (BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    if (!(columnNames.count == relations.count && relations.count == values.count)) {
        NSLog(@"columnNames、relations、values元素个数请保持一致!");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    NSString *appendStr = isAnd ? @"and" : @"or" ;

    NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"delete from %@ where",tableName];
    
    [columnNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *columnName = obj;
        NSString *relation = self.CWDBNameToValueRelationTypeDic[relations[idx]];
        id value = values[idx];
        NSString *nameValueStr = [NSString stringWithFormat:@" %@ %@ '%@' ",columnName,relation,value];
        [deleteSql appendString:nameValueStr];
        if (idx != columnNames.count - 1) {
            [deleteSql appendString:appendStr];
        }
    }];
    
    BOOL result = [CWDatabase execSQL:deleteSql uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return result;
}

#pragma mark - 更新数据库表结构、数据迁移
// 更新表并迁移数据
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId{
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    // 1.创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [CWModelTool tmpTableName:cls targetId:targetId];
    NSString *tableName = [CWModelTool tableName:cls targetId:targetId];
    
    // 类方法可以直接响应 对象方法[cls new] responds...
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
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
    NSArray *oldNames = [CWSqliteTableTool allTableColumnNames:tableName uid:uid];
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
            if ([oldNames containsObject:newNameToOldNameDic[columnName]]) {
                oldName = newNameToOldNameDic[columnName];
            }
        }
        // 如果老表包含了新的列名，应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && [columnName isEqualToString:oldName]) ) {
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
    
    BOOL result = [CWDatabase execSqls:execSqls uid:uid];
    [CWDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

#pragma mark - 枚举与字符串的映射关系
+ (NSDictionary *)CWDBNameToValueRelationTypeDic {
    return @{@(CWDBRelationTypeMore):@">",
             @(CWDBRelationTypeLess):@"<",
             @(CWDBRelationTypeEqual):@"=",
             @(CWDBRelationTypeMoreEqual):@">=",
             @(CWDBRelationTypeLessEqual):@"<="
             };
}

@end
