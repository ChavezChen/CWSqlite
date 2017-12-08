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

- (void)testQueryModels {
    NSArray *models = [CWSqliteModelTool queryAllModels:[Student class] uid:@"Chavez" targetId:nil];
    NSLog(@"query models : %@",models);
    XCTAssertNotNil(models);
}

@end
