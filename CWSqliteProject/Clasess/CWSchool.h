//
//  CWSchool.h
//  CWDBProject
//
//  Created by mac on 2017/12/26.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CWModelProtocol.h"


@class CWTeacher;
@class CWStudent;
@class CWClass;

#pragma mark - 学校
@interface CWSchool : NSObject<CWModelProtocol>

@property (nonatomic,assign) int schoolId; // 学校ID
@property (nonatomic,assign) float grade; // 学校评分
@property (nonatomic,copy) NSString *schoolName; // 学校名称
@property (nonatomic,strong) NSURL *schoolUrl; // 学校主页地址
@property (nonatomic,strong) NSArray *classes; // 学校所有班级(里面是CWClass模型)
@property (nonatomic,strong) CWTeacher *schoolMaster; // 校长
@property (nonatomic,strong) CWClass *bestClass; // 学校最优秀的班级
@property (nonatomic,strong) CWStudent *bestStudent; // 学校最优秀的学生

@end


#pragma mark - 班级
@interface CWClass : NSObject

@property (nonatomic,assign) int classId; // 班级
@property (nonatomic,copy) NSString *className; // 班级名称
@property (nonatomic,strong) NSArray *teachers; // 班级所有老师
@property (nonatomic,strong) NSMutableArray *students; // 班级所有学生
@property (nonatomic,strong) CWTeacher *classTeacher;  // 班主任
@property (nonatomic,strong) CWStudent *classMonitor;  // 班长

@end

#pragma mark - 学生
@interface CWStudent : NSObject

@property (nonatomic,assign) int stuId; // 学号
@property (nonatomic,copy) NSString *name; // 姓名
@property (nonatomic,assign) int age;  // 年龄
@property (nonatomic,assign) float height; // 身高
@property (nonatomic,assign) float weight; // 体重
@property (nonatomic,copy) NSString *gender; // 性别
@property (nonatomic,copy) NSString *personality; // 性格
@property (nonatomic,strong) UIImage *photo; // 照片
@property (nonatomic,strong) NSDictionary *scoreDict; // 成绩  @{ @"语文":@(90) , @"数学":@(10) }

@end

#pragma mark - 老师
@interface CWTeacher : NSObject

@property (nonatomic,assign) int teachId; // 教师工号
@property (nonatomic,copy) NSString *name; // 姓名
@property (nonatomic,assign) int age;  // 年龄
@property (nonatomic,assign) float height; // 身高
@property (nonatomic,assign) float weight; // 体重
@property (nonatomic,copy) NSString *gender; // 性别
@property (nonatomic,strong) UIImage *photo; // 照片
@property (nonatomic,copy) NSString *subjects; // 所教科目

@end

