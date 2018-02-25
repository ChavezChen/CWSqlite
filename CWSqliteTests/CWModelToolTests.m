//
//  CWModelToolTests.m
//  CWDBTests
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CWModelTool.h"
#import "Student.h"
#import "School.h"

@interface CWModelToolTests : XCTestCase

@end

@implementation CWModelToolTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testIvarNameTypeDict {
    NSDictionary *dict = [CWModelTool classIvarNameAndTypeDic:[Student class]];
    NSLog(@"Student------%@",dict);
    XCTAssertNotNil(dict);
}


- (void)testSqlColumnNamesAndTypesStr {
    NSString *sqlStr = [CWModelTool sqlColumnNamesAndTypesStr:[Student class]];
    NSLog(@"Student ivar str : %@",sqlStr);
    XCTAssertNotNil(sqlStr);
}

- (void)testDictWithModel {
    
    School *school = [[School alloc] init];
    school.name = @"清华大学";
    school.schoolId = 1;
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 10000;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
//    stu.dict = @{@"name" : @"chavez"};
//    stu.arrayM = [@[@"chavez",@"cw",@"ccww"] mutableCopy];
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:@"attributedStr,attributedStr"];
    stu.attributedString = attributedStr;
    // 模型嵌套模型
    stu.school = school;
    
    // 模型转字典
    NSDictionary *dict = [CWModelTool dictWithModel:stu];
    NSLog(@"-----%@",dict);
    // 字典转字符串
    NSString *jsonStr = [CWModelTool stringWithDict:dict];
    NSLog(@"=====%@",jsonStr);
    
    // 字符串转字典
    NSDictionary *dict1 = [CWModelTool dictWithString:jsonStr type:NSStringFromClass([stu class])];
    NSLog(@"-----%@",dict);
    // 字典转模型
    id model = [CWModelTool model:[stu class] Dict:dict1];
    NSLog(@"=====%@",model);
}

- (void)testStringWithArray {
    
    School *school = [[School alloc] init];
    school.name = @"清华大学";
    school.schoolId = 1;
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 10000;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
    stu.dict = @{@"name" : @"chavez"};
    stu.arrayM = [@[@"chavez",@"cw",@"ccww"] mutableCopy];
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:@"attributedStr,attributedStr"];
    stu.attributedString = attributedStr;
    stu.school = school;
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:school];
    [arr addObject:stu];
    [arr addObject:@(1)];
    [arr addObject:@(1.5)];
    [arr addObject:@"haha"];
    [arr addObject:@[@"1",@(2)]];
    
    NSArray *a = @[school,stu];
    NSMutableArray *aM = [NSMutableArray arrayWithArray:a];
    [arr addObject:aM];
    
    NSString *str = [CWModelTool stringWithArray:arr];
    
    NSLog(@"%@",str);
    
    NSArray *arrar = [CWModelTool arrayWithString:str type:NSStringFromClass([NSMutableArray class])];
    
    NSLog(@"=================%@",arrar);
}

- (void)testStringWithDict {
    
    School *school = [[School alloc] init];
    school.name = @"清华大学";
    school.schoolId = 1;
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 10000;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
    stu.dict = @{@"school" : school};
    stu.arrayM = [@[@"chavez",@"cw",@"ccww"] mutableCopy];
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:@"attributedStr,attributedStr"];
    stu.attributedString = attributedStr;
    stu.school = school;
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    
    dictM[@"sch"] = school;
    dictM[@"stu"] = stu;
    dictM[@"xxx"] = @(1.5);
    dictM[@"yyy"] = @(1);
    dictM[@"arr"] = @[@"cw",@(111)];
    dictM[@"arrM"] = [NSMutableArray arrayWithArray:@[@"arrM1",@"arrM2"]];
    dictM[@"dict"] = @{@"dictKey" : @"dictValue"};
    dictM[@"dictM"] = [NSMutableDictionary dictionaryWithDictionary:@{@"dictMKey" : @"dictMValue"}];
    
//    NSDictionary *dict = @{@"arrayKey" : @[@"cw",@(111)] ,
//                       @"arrayMKey" : [NSMutableArray arrayWithArray:@[@"arrM1",@"arrM2"]] ,
//                       @"dictKey" : @{@"dictKey" : @"dictValue"} ,
//                       @"dictMkey" : [NSMutableDictionary dictionaryWithDictionary:@{@"dictMKey" : @"dictMValue"}] ,
//                       @"xxx" : @(1.5) ,
//                       @"stu" : stu,
//                       };
    
    
    NSString *str = [CWModelTool stringWithDict:dictM];
    NSLog(@"%@",str);
    
    NSLog(@"============%@",dictM);
    NSDictionary *resultDict = [CWModelTool dictWithString:str type:NSStringFromClass([dictM class])];
    NSLog(@"------------%@",resultDict);
    
}


@end
