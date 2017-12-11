//
//  Student.m
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "Student.h"

@implementation Student

#pragma mark - CWModelProtocol
+ (NSString *)primaryKey {
    return @"stuId";
}

//+ (NSDictionary *)newNameToOldNameDic {
//    return @{@"score":@"sss"};
//}

- (NSString *)description {
    
    NSString *str = [NSString stringWithFormat:@" stuId = %d , name = %@ , age = %d , height = %d ,score = %f",_stuId,_name,_age,_height,score];
    
    return str;
}

@end
