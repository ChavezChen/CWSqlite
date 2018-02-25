//
//  CWModelProtocol.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CWModelProtocol <NSObject>

@required
/**
 操作模型必须实现的方法，通过这个方法获取主键信息
 
 @return 主键字符串
 */
+ (NSString *)primaryKey;

@optional
/**
 字段更名
 将旧字段名称的值迁移到新字段名称下 { 新字段名称(key) : 旧字段名称,数据表里的字段名(value) }
  @return 映射表格
 */
+ (NSDictionary *)newNameToOldNameDic;

/**
 忽略的字段数组
 
 @return 不存入数据库的字段数组
 */
+ (NSArray *)ignoreColumnNames;

@end
