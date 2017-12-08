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

@end
