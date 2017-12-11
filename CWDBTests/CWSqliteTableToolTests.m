//
//  CWSqliteTableToolTests.m
//  CWDBTests
//
//  Created by mac on 2017/12/11.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CWSqliteTableTool.h"
#import "Student.h"

@interface CWSqliteTableToolTests : XCTestCase

@end

@implementation CWSqliteTableToolTests

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

- (void)testAllTableColumnNames {
    
    NSArray *array = [CWSqliteTableTool allTableColumnNames:@"Student" uid:@"Chavez"];
    NSLog(@"names : %@",array);
    XCTAssertNotNil(array);
}

- (void)testIsTableNeedUpdate {
    BOOL isNeedUpdate = [CWSqliteTableTool isTableNeedUpdate:[Student class] uid:@"Chavez" targetId:nil];
    XCTAssertFalse(isNeedUpdate);
}

- (void)testUpdateTable {
    BOOL result = [CWSqliteTableTool updateTable:[Student class] uid:@"Chavez" targetId:nil];
    XCTAssertTrue(result);
}

@end
