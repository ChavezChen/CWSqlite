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
}
@property (nonatomic,assign) int stuId; // 学号
@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) int age;
@property (nonatomic,assign) int height;
@property (nonatomic,assign) float weight;
//@property (nonatomic,assign) float hh;

@end
