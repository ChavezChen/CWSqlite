//
//  CWDatabaseTest.m
//  CWDBTests
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CWDatabase.h"

@interface CWDatabaseTest : XCTestCase

@end

@implementation CWDatabaseTest

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


- (void)testOpenDB {
    BOOL result = [CWDatabase openDB:@"CWDB"];
    XCTAssertEqual(YES, result);
}


- (void)testOpenDBAndExceSql {
    NSString *sql = @"create table if not exists Student(id integer , name text not null, age integer, score real,primary key(id))";
    
    BOOL result = [CWDatabase execSQL:sql uid:nil];
    XCTAssertEqual(YES, result);
    
    BOOL result1 = [CWDatabase execSQL:sql uid:@"Chavez"];
    XCTAssertEqual(YES, result1);
}








@end
