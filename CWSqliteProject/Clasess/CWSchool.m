//
//  CWSchool.m
//  CWDBProject
//
//  Created by mac on 2017/12/26.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWSchool.h"

#pragma mark - 学校
@implementation CWSchool

#pragma mark 返回主键信息
+ (NSString *)primaryKey {
    return @"schoolId";
}

//// 忽略的成员变量
//+ (NSArray *)ignoreColumnNames {
//    // 不想将学校评分存入数据库
//    return @[@"grade"];
//}

@end

#pragma mark - 班级
@implementation CWClass

@end

#pragma mark - 老师
@implementation CWTeacher

@end

#pragma mark - 学生
@implementation CWStudent

@end
