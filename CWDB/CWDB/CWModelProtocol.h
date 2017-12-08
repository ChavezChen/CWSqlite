//
//  CWModelProtocol.h
//  CWDB
//
//  Created by 陈旺 on 2017/12/3.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CWModelProtocol <NSObject>

@required
/**
 操作模型必须实现的方法，通过这个方法获取主键信息
 
 @return 主键字符串
 */
+ (NSString *)primaryKey;

@end
