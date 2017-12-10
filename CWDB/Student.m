//
//  Student.m
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "Student.h"

@implementation Student

+ (NSString *)primaryKey {
    return @"stuId";
}



- (NSString *)description {
    
    NSString *str = [NSString stringWithFormat:@" stuId = %d , name = %@ , age = %d , height = %d ,score = %f",_stuId,_name,_age,_height,score];
    
    return str;
}

@end
