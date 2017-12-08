//
//  CWSqliteTableTool.h
//  CWDB
//
//  Created by mac on 2017/12/7.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWSqliteTableTool : NSObject

// 表格是否存在
+ (BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid;


@end
