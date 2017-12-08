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



@end
