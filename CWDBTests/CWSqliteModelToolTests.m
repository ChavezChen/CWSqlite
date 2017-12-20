//
//  CWSqliteModelToolTests.m
//  CWDBTests
//
//  Created by mac on 2017/12/6.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CWSqliteModelTool.h"
#import "Student.h"

@interface CWSqliteModelToolTests : XCTestCase

@end

@implementation CWSqliteModelToolTests

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

- (void)testCreateSQLTable {
    BOOL result = [CWSqliteModelTool createSQLTable:[Student class] uid:@"CWDB" targetId:@"53class"];
    XCTAssertTrue(result);
}

#pragma mark - 测试插入数据
// 测试插入数据
- (void)testInsertModel {
    // 创建表格
    BOOL result = [CWSqliteModelTool createSQLTable:[Student class] uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 10086;
    stu.name = @"Alibaba";
    stu.age = 16;
    stu.height = 165;
    // 插入数据
    BOOL result1 = [CWSqliteModelTool insertModel:stu uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result1);
    
    Student *stu1 = [[Student alloc] init];
    stu1.stuId = 10010;
    stu1.name = @"Tencent";
    stu1.age = 17;
    stu1.height = 182;
    // 插入数据
    BOOL result2 = [CWSqliteModelTool insertModel:stu1 uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result2);
    
    Student *stu2 = [[Student alloc] init];
    stu2.stuId = 10000;
    stu2.name = @"Baidu";
    stu2.age = 18;
    stu2.height = 180;
    // 插入数据
    BOOL result3 = [CWSqliteModelTool insertModel:stu2 uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result3);
    
}
#pragma mark - 测试数据查询
// 测试查询数据
- (void)testQueryModels {
    NSArray *models = [CWSqliteModelTool queryAllModels:[Student class] uid:@"Chavez" targetId:nil];
//    NSLog(@"query models : %@",models);
    for (Student *stu in models) {
        NSLog(@"--------stu : %@",stu);
    }
    
    XCTAssertNotNil(models);
}
// 测试条件查询
- (void)testQueryModelsWithRelation {
    NSArray *models = [CWSqliteModelTool querModels:[Student class] name:@"age" relation:CWDBRelationTypeLessEqual value:@"50" uid:@"Chavez" targetId:nil];
    NSLog(@"query models : %@",models);
    XCTAssertNotNil(models);
}
// 测试多个条件查询
- (void)testQueryModelWithMultipleConditions {
    // 根据多个条件与查询
    NSArray *array = [CWSqliteModelTool querModels:[Student class] columnNames:@[@"age",@"score",@"height"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeLessEqual),@(CWDBRelationTypeMoreEqual)] values:@[@(100),@(20),@(182)] isAnd:YES uid:@"Chavez" targetId:nil];
    
    NSLog(@"----------%@",array);
    XCTAssertNotNil(array);
    
    // 根据多个条件或查询
    NSArray *array1 = [CWSqliteModelTool querModels:[Student class] columnNames:@[@"age",@"age",@"height"] relations:@[@(CWDBRelationTypeEqual),@(CWDBRelationTypeEqual),@(CWDBRelationTypeEqual)] values:@[@(100),@(16),@(111)] isAnd:NO uid:@"Chavez" targetId:nil];
    NSLog(@"==========%@",array1);
    
    XCTAssertNotNil(array1);
}
#pragma mark - 测试数据更新
// 测试创建表格并插入数据
- (void)testCreateTableAndInsertModel {
    Student *stu = [[Student alloc] init];
    stu.stuId = 110;
    stu.name = @"中国公安";
    stu.age = 100;
    stu.height = 190;
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:@"国防科技大学"];
    XCTAssertTrue(result);
    
    Student *stu1 = [[Student alloc] init];
    stu1.stuId = 119;
    stu1.name = @"中国火警";
    stu1.age = 101;
    stu1.height = 200;
    BOOL result1 = [CWSqliteModelTool insertOrUpdateModel:stu1 uid:@"Chavez" targetId:@"国防科技大学"];
    XCTAssertTrue(result1);
}
// 测试更新数据
- (void)testUpdateModel {
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 110;
    stu.name = @"中国公安警察支队";
    stu.age = 90;
    stu.height = 189;
    
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:@"国防科技大学"];
    XCTAssertTrue(result);
}

// 测试更新数据表
- (void)testUpdateTable {
    BOOL result = [CWSqliteModelTool updateTable:[Student class] uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
}
// 测试更新数据表、插入数据、字段改名
- (void)testUpdateTableInsertModelAndRenameColumn {
    Student *stu = [[Student alloc] init];
    stu.stuId = 10000;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
}

#pragma mark - 测试删除数据
// 测试根据单个条件删除数据
- (void)testDeleteModel {
    BOOL result = [CWSqliteModelTool deleteModel:[Student class] columnName:@"age" relation:CWDBRelationTypeLessEqual value:@(20) uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
}

// 根据多个条件删除数据
- (void)testDeleteModelWithMultipleConditions {
    
    BOOL result = [CWSqliteModelTool deleteModel:[Student class] columnNames:@[@"age",@"score",@"height"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeLessEqual),@(CWDBRelationTypeMoreEqual)] values:@[@(100),@(20),@(190)] isAnd:YES uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
}

// 测试模型，数组，字典各种嵌套(复杂)的模型
- (void)testInserComplicatedModel{
    
    School *school1 = [[School alloc] init];
    school1.name = @"北京大学";
    school1.schoolId = 2;
    
    School *school = [[School alloc] init];
    school.name = @"清华大学";
    school.schoolId = 1;
    school.school1 = school1;
    
    Student *stu = [[Student alloc] init];
    stu.stuId = 10000;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
    stu.dict = @{@"name" : @"chavez"};
    // 字典嵌套模型
    stu.dictM = [@{@"清华大学" : school , @"北京大学" : school1 , @"money" : @(100)} mutableCopy];
    // 数组嵌套字典，字典嵌套模型
    stu.arrayM = [@[@"chavez",@"cw",@"ccww",@{@"清华大学" : school}] mutableCopy];
    // 数组嵌套模型
    stu.array = @[@(1),@(2),@(3),school,school1];
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:@"attributedStr,attributedStr"];
    stu.attributedString = attributedStr;
    // 模型嵌套模型
    stu.school = school;
    
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
    
    XCTAssertTrue(result);
}


@end
