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

#pragma mark - 插入或更新数据

#pragma mark 简易方法
/**
 简易方法!向数据库单个插入或者更新数据.

 @param model 需要保存或者更新的模型
 @return 插入或者更新数据是否成功，成功返回YES 失败返回NO
 */
+ (BOOL)insertOrUpdateModel:(id)model;

/**
 简易方法!向数据库批量插入或者更新数据.

 @param modelsArray 模型的数组，数组内的模型必须是同一类型，否则会失败
 @return 插入或者更新数据是否成功，成功返回YES 失败返回NO。（事务控制，必须全部插入成功才返回YES，有一条失败则返回NO）
 */
+ (BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray;

#pragma mark 完整方法
/**
 向数据库批量插入或者更新数据
 --方法内部会根据所传模型的主键值来判断数据库内是否存在数据；
 --如果数据库对应表格内存在主键一样的数据，方法内部会进行更新操作，将原有的模型的数据更新为最新的模型的数据。
 --如果数据库对应表格内不存在主键一样的数据，方法内将会直接执行插入数据库操作

 @param modelsArray     模型的数组，数组内的模型必须是同一类型，否则会失败
 @param uid             userId，主要用于数据库的名称，可为nil，当为nil时我们会默认将数据库名称设置为CWDB，不同的uid对应不同的数据              库，比如账号张三登陆，创建的数据库则为张三，李四登陆创建的数据库则为李四
 @param targetId        目标id，可为nil，主要用于分辨数据库表名，方法内部创建数据库表时根据模型的类型className来创建对应的数据库表，但是有的场景并不适合仅用className为表名，比如聊天记录，和张三聊天希望是和张三聊天对应的一个表，和李四聊天就对应另一个表，带上目标ID我们就能将要保存的数据分别给张三、李四对应的表内存储，查询数据的时候会按照targetId找到对应的表格进行查询，如果你不需要同个模型分别建多张表格，传nil即可
 @return                插入或者更新数据是否成功，成功返回YES 失败返回NO。（事务控制，必须全部插入成功才返回YES，有一条失败则返回NO）
 */
+ (BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray
                         uid:(NSString *)uid
                    targetId:(NSString *)targetId;


/**
 向数据库单个插入或者更新数据

 @param model       需要保存或者更新的模型
 @param uid         userId，可为nil，作用看前一个方法（批量插入数据）的解释
 @param targetId    目标id，可为nil，作用看前一个方法（批量插入数据）的解释
 @return            插入或者更新数据是否成功，成功返回YES 失败返回NO
 */
+ (BOOL)insertOrUpdateModel:(id)model
                        uid:(NSString *)uid
                   targetId:(NSString *)targetId;


#pragma mark - 数据查询

#pragma mark 简易方法
/**
 简易方法!查询数据库所有数据.

 @param cls 模型的类型 [obj class]
 @return  查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryAllModels:(Class)cls;

/**
 简易方法!根据单个条件查询数据.
 比如我想查找数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age大于10
 
 @param cls             模型的类型
 @param name            条件字段名称
 @param relation        字段与值的关系，大于、小于、等于......
 @param value           字段的值
 @return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
                    name:(NSString *)name
                relation:(CWDBRelationType)relation
                   value:(id)value;

/**
 简易方法!根据多个条件与查询(and必须所有条件都满足才能查询到 or 满足其中一个条件就都查询得到)
 比如我想查找数据库内Student模型的 age大于10岁，并且 height小于等于100厘米的小朋友：
 第一个参数传 @[@"age",@"height"]
 第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
 第三个参数传 @[@(10),@(100)]
 第四个参数传 YES，如果 age>10 和 height<=100 只要满足其中一个就行 就传NO
 
 @param cls             模型的类型
 @param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
 @param relations       字段与值的关系数组
 @param values          字段的值数组
 @param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
 @return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
             columnNames:(NSArray <NSString *>*)columnNames
               relations:(NSArray <NSNumber *>*)relations
                  values:(NSArray *)values
                   isAnd:(BOOL)isAnd;

/**
 简单分页查询
 从数据表内跳过offset条数据，取limit条数据。
 假设：limit传10，offset传1 表示： cls模型表内跳过1条数据取10条数据
 @param cls 模型的类型
 @param limit 查找多少条
 @param offset 偏移多少条
 @return 查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
                   limit:(NSInteger)limit
                  offset:(NSInteger)offset;

/**
 根据条件分页查询
 从数据表内跳过offset条数据，取满足条件columnName、relation、value的数据，并按照orderName字段升序或者降序排列。
 例如：我想取班级里面学号大于20的同学按照英语成绩降序的方式排序，并取其中的第5-10名,可以这样传:
 columnName:stuId;   relation:CWDBRelationTypeMore;  value:@(20);    orderName:english;  isDesc:YES;    limit:5;    offset:5;
 @param cls 模型的类型
 @param columnName 条件字段名称 （可为空，代表没有条件筛选）
 @param relation 关系 是否传值必须和columnName字段一致
 @param value 条件字段的值 是否传值必须和columnName字段一致
 @param orderName 排序的字段名称 （可为空，代表没有条件排序）
 @param isDesc 是否为降序
 @param limit 查找多少条
 @param offset 偏移多少条
 @return 查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
              cloumnName:(NSString *)columnName
                relation:(CWDBRelationType)relation
                   value:(id)value
               orderName:(NSString *)orderName
                  isDesc:(BOOL)isDesc
                   limit:(NSInteger)limit
                  offset:(NSInteger)offset;

#pragma mark 完整方法
/**
 查询对应uid的数据库内对应targetId表内的所有数据

 @param cls         模型的类型 [obj class]
 @param uid         userId,可为nil，保存数据时传的啥，这里就传啥，（使用简易方法保存的数据传nil即可）
 @param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
 @return            查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryAllModels:(Class)cls
                        uid:(NSString *)uid
                   targetId:(NSString *)targetId;


/**
 自己传sql语句查询
 写sql语句时，表名为插入数据时的 模型类型的字符串+targetId
 比如：插入一个 Student模型时 targetId为张三，那么这个表名为 Student张三，在自己写sql语句时表名通过这个规则写
 提供写法：[NSString stringWithFormat:@"%@%@",NSStringFromClass([student class]),targetId] 这样就返回了正确的表名
 
 @param cls     模型的类型，返回的数据内的元素为该类型的模型，请与保存数据时的模型类型对应
 @param sql     sql语句，如 select * from 表名 where xx = xx or/and cc = cc ...
 @param uid     userId,可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @return        查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
                     Sql:(NSString *)sql
                     uid:(NSString *)uid;

//

/**
 根据单个条件查询数据
 比如我想查找数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age大于10
 
 @param cls             模型的类型
 @param name            条件字段名称
 @param relation        字段与值的关系，大于、小于、等于......
 @param value           字段的值
 @param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId        targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
                    name:(NSString *)name
                relation:(CWDBRelationType)relation
                   value:(id)value uid:(NSString *)uid
                targetId:(NSString *)targetId;

/**
 根据多个条件与查询(and必须所有条件都满足才能查询到 or 满足其中一个条件就都查询得到)
 比如我想查找数据库内Student模型的 age大于10岁，并且 height小于等于100厘米的小朋友：
 第一个参数传 @[@"age",@"height"]
 第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
 第三个参数传 @[@(10),@(100)]
 第四个参数传 YES，如果 age>10 和 height<=100 只要满足其中一个就行 就传NO
 
 @param cls             模型的类型
 @param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
 @param relations       字段与值的关系数组
 @param values          字段的值数组
 @param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
 @param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId        目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
             columnNames:(NSArray <NSString *>*)columnNames
               relations:(NSArray <NSNumber *>*)relations
                  values:(NSArray *)values
                   isAnd:(BOOL)isAnd uid:(NSString *)uid
                targetId:(NSString *)targetId;


/**
 简单分页查询
 从数据表内跳过offset条数据，取limit条数据。
 假设：limit传10，offset传1 表示： cls模型表内跳过1条数据取10条数据
 @param cls 模型的类型
 @param limit 查找多少条
 @param offset 偏移多少条
 @param uid userId,可为nil，保存数据时传的啥，这里就传啥，（使用简易方法保存的数据传nil即可）
 @param targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
 @return 查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
                   limit:(NSInteger)limit
                  offset:(NSInteger)offset
                     uid:(NSString *)uid
                targetId:(NSString *)targetId;

/**
 根据条件分页查询
 从数据表内跳过offset条数据，取满足条件columnName、relation、value的数据，并按照orderName字段升序或者降序排列。
 例如：我想取班级里面学号大于20的同学按照英语成绩降序的方式排序，并取其中的第5-10名,可以这样传:
 columnName:stuId;   relation:CWDBRelationTypeMore;  value:@(20);    orderName:english;  isDesc:YES;    limit:5;    offset:5;
 @param cls 模型的类型
 @param columnName 条件字段名称 （可为空，代表没有条件筛选）
 @param relation 关系 是否传值必须和columnName字段一致
 @param value 条件字段的值 是否传值必须和columnName字段一致
 @param orderName 排序的字段名称 （可为空，代表没有条件排序）
 @param isDesc 是否为降序
 @param limit 查找多少条
 @param offset 偏移多少条
 @param uid userId,可为nil，保存数据时传的啥，这里就传啥，（使用简易方法保存的数据传nil即可）
 @param targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
 @return 查询到的结果数组，数组内元素为第一个参数cls类型的模型
 */
+ (NSArray *)queryModels:(Class)cls
              cloumnName:(NSString *)columnName
                relation:(CWDBRelationType)relation
                   value:(id)value
               orderName:(NSString *)orderName
                  isDesc:(BOOL)isDesc
                   limit:(NSInteger)limit
                  offset:(NSInteger)offset
                     uid:(NSString *)uid
                targetId:(NSString *)targetId;


#pragma mark -数据删除

#pragma mark 简易方法
/**
 简易方法!删除指定模型.
 会根据model的主键值来删除对应的数据，模型不一定要完全一样，删除的数据只和主键相关

 @param model 要删除的模型
 @return 删除是否成功
 */
+ (BOOL)deleteModel:(id)model;


/**
 简易方法!删除数据库表中所有数据.

 @param cls 模型类型
 @param isKeep 是否保留表，传YES表保留只删除表内所有数据，传NO直接将表销毁
 @return 删除是否成功
 */
+ (BOOL)deleteTableAllData:(Class)cls isKeepTable:(BOOL)isKeep;

/**
 简易方法!根据单个条件删除数据库内数据.
 
 比如我想删除数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age>10
 
 @param cls             模型的类型
 @param name            条件字段名称
 @param relation        字段与值的关系，大于、小于、等于......
 @param value           字段的值
 @return                删除是否成功
 */
+ (BOOL)deleteModels:(Class)cls
          columnName:(NSString *)name
            relation:(CWDBRelationType)relation
               value:(id)value;

/**
 简易方法!根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)
 比如我想删除数据库内Student模型的age大于10岁并且height小于等于100厘米的所有小朋友：
 第一个参数传 @[@"age",@"height"]
 第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
 第三个参数传 @[@(10),@(100)]
 第四个参数传 YES；  如果age>10和height<=100只要满足其中一个就删除就传NO
 
 @param cls             模型的类型
 @param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
 @param relations       字段与值的关系数组
 @param values          字段的值数组
 @param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
 @return                删除是否成功
 */
+ (BOOL)deleteModels:(Class)cls
         columnNames:(NSArray <NSString *>*)columnNames
           relations:(NSArray <NSNumber *>*)relations
              values:(NSArray *)values
               isAnd:(BOOL)isAnd;

#pragma mark 完整方法
/**
 删除数据库表中所有数据

 @param cls         模型类型
 @param uid         userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
 @param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @param isKeep      是否保留表，传YES表保留只删除表内所有数据，传NO直接将表销毁
 @return            删除是否成功
 */
+ (BOOL)deleteTableAllData:(Class)cls
                       uid:(NSString *)uid
                  targetId:(NSString *)targetId
               isKeepTable:(BOOL)isKeep;


/**
 删除指定模型,会根据model的主键值来删除对应的数据，模型不一定要完全一样，输出的数据只和主键相关

 @param model       要删除的模型
 @param uid         用户id，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return            删除是否成功
 */
+ (BOOL)deleteModel:(id)model
                uid:(NSString *)uid
           targetId:(NSString *)targetId;


/**
 自己传sql语句删除
 写sql语句时，表名为插入数据时的 模型类型的字符串+targetId
 比如：插入一个 Student模型时 targetId为张三，那么这个表名为 Student张三，在自己写sql语句时表名通过这个规则写
 提供写法：[NSString stringWithFormat:@"%@%@",NSStringFromClass([student class]),targetId] 这样就返回了正确的表名
 
 @param deleteSql   执行的sql语句
 @param uid         用户id，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @return            删除是否成功
 */
+ (BOOL)deleteModelWithSql:(NSString *)deleteSql uid:(NSString *)uid;



/**
 根据单个条件删除数据库内数据
 
 比如我想删除数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age>10

 @param cls             模型的类型
 @param name            条件字段名称
 @param relation        字段与值的关系，大于、小于、等于......
 @param value           字段的值
 @param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId        targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return                删除是否成功
 */
+ (BOOL)deleteModels:(Class)cls
          columnName:(NSString *)name
            relation:(CWDBRelationType)relation
               value:(id)value
                 uid:(NSString *)uid
            targetId:(NSString *)targetId;


/**
 根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)
 比如我想删除数据库内Student模型的age大于10岁并且height小于等于100厘米的所有小朋友：
 第一个参数传 @[@"age",@"height"]
 第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
 第三个参数传 @[@(10),@(100)]
 第四个参数传 YES；  如果age>10和height<=100只要满足其中一个就删除就传NO
 
 @param cls             模型的类型
 @param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
 @param relations       字段与值的关系数组
 @param values          字段的值数组
 @param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
 @param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId        目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return                删除是否成功
 */
+ (BOOL)deleteModels:(Class)cls
         columnNames:(NSArray <NSString *>*)columnNames
           relations:(NSArray <NSNumber *>*)relations
              values:(NSArray *)values
               isAnd:(BOOL)isAnd
                 uid:(NSString *)uid
            targetId:(NSString *)targetId;

#pragma mark - 更新数据库表结构，数据迁移
/**
 更新数据库某表的结构并且数据迁移，大多数情况下，你并不需要自行调用这个方法，因为在我们插入或这更新数据的方法内，已经做了判断，如果需要更新数据库表结构，在插入或者更新数据时就已经做了更新与迁移了，如果你实在需要自行执行更新操作，调用此方法即可

 @param cls         模型所属的类（模型所属的类+targetId为需要更新的数据库表的名字）
 @param uid         userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return            更新是否成功
 */
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

@end
