//
//  CWSqliteModelTool.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//  数据库模型工具类,主要通过调用这个工具的API实现操作数据库

#import <Foundation/Foundation.h>
#import "CWModelProtocol.h"

typedef NS_ENUM(NSUInteger,CWDBRelationType) {
    CWDBRelationTypeMore = 0,       // 大于 >
    CWDBRelationTypeLess,       // 小于 <
    CWDBRelationTypeEqual,      // 等于 =
    CWDBRelationTypeMoreEqual,  // 大于等于 >=
    CWDBRelationTypeLessEqual   // 小于等于 <=
};


@interface CWSqliteModelTool : NSObject

/**
 创建数据库表

 @param cls 模型类型
 @param uid 用户userid，用于数据库名称
 @param targetId 目标id，用于数据库表名称  表的名称为:className+targetId
 @return 创建成功或失败
 */
+ (BOOL)createSQLTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

// 插入数据库
+ (BOOL)insertModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;

// 插入或者更新数据
+ (BOOL)insertOrUpdateModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;


#pragma mark -查询
// 查询所有数据
+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

// 自己传sql语句查询
+ (NSArray *)querModels:(Class)cls Sql:(NSString *)sql uid:(NSString *)uid;

// 根据单个条件查询
+ (NSArray *)querModels:(Class)cls name:(NSString *)name relation:(CWDBRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId;

#pragma mark -删除
// 删除指定数据,会根据model的主键值来删除对应的数据
+ (BOOL)deleteModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;

// 根据单个条件删除
+ (BOOL)deleteModel:(Class)cls columnName:(NSString *)name relation:(CWDBRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId;

// 根据多个条件删除
+ (BOOL)deleteModel:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values uid:(NSString *)uid targetId:(NSString *)targetId;



#pragma mark - 字段改名，更新数据库表结构，数据迁移
// 更新数据库表结构、字段改名、数据迁移
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

@end
