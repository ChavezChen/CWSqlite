//
//  Student.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CWModelProtocol.h"

@interface Student : NSObject<CWModelProtocol>
{
    float score;
    NSInteger score2;
    NSUInteger score3;
}
@property (nonatomic,assign) int stuId; // 学号
@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) int age;
@property (nonatomic,assign) int height;
@property (nonatomic,assign) float weight;
//@property (nonatomic,copy) NSString *name1;
@property (nonatomic,assign) float hh;

@property (nonatomic,copy) NSAttributedString *attributedString;

@property (nonatomic,strong) NSDictionary *dict;

@property (nonatomic,strong) NSDictionary *dictM;

@property (nonatomic,strong) NSArray *array;

@property (nonatomic,strong) NSMutableArray *arrayM;


@end

