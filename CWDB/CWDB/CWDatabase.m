//
//  CWDatabase.m
//  CWDB
//
//  Created by ChavezChen on 2017/12/2.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWDatabase.h"
#import <sqlite3.h>


//#define kCWDBCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject

#define kCWDBCachePath @"/Users/mac/Desktop"

@interface CWDatabase ()

@end

@implementation CWDatabase

sqlite3 *cw_database = nil;

static NSTimeInterval _startBusyRetryTime; // 第一次重试的时间

+ (BOOL)execSQL:(NSString *)sql uid:(NSString *)uid {
    
    if (![self openDB:uid]) {
        return NO;
    }
    
    char *errmsg = nil;
    int result = sqlite3_exec(cw_database, sql.UTF8String, nil, nil, &errmsg);
    
    [self closeDB];
    
    if (result != SQLITE_OK) {
        NSLog(@"exec sql error : %s",errmsg);
        return NO;
    }
    return YES;
}



// 返回0 则不重试操作数据库，返回非0 将不断尝试操作数据库
static int CWDBBusyCallBack(void *f, int count) {
    // count为回调这个函数的次数
    if (count == 0) {
        _startBusyRetryTime = [NSDate timeIntervalSinceReferenceDate];
        return 1;
    }
    
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _startBusyRetryTime;
    if (delta < 2) { //如果本次尝试操作距离第一次尝试操作 小于2秒 （最多尝试操作数据库2秒钟）
        int actualSleepInMilliseconds = sqlite3_sleep(100); // 休眠100毫秒
        if (actualSleepInMilliseconds != 100) {
            NSLog(@"⚠️警告:请求休眠100毫秒，但是实际休眠%d毫秒,Maybe SQLite wasn't built with HAVE_USLEEP=1?",actualSleepInMilliseconds);
        }
        return 1;
    }
    // 反复尝试操作超过2秒，返回0不再尝试操作数据库
    return 0;
}


#pragma 私有方法
+ (BOOL)openDB:(NSString *)uid {
    // 数据库名称
    NSString *dbName = @"CWDB.sqlite";
    if (uid.length != 0) {
        dbName = [NSString stringWithFormat:@"%@.sqlite", uid];
    }
    // 数据库路径
    NSString *dbPath = [kCWDBCachePath stringByAppendingPathComponent:dbName];
    // 打开数据库
    int result = sqlite3_open(dbPath.UTF8String, &cw_database);
    if (result != SQLITE_OK) {
        NSLog(@"打开数据库失败! : %d",result);
        return NO;
    }
    // 检测当前连接的数据库是否处于busy状态，处于则会回调CWDBBusyCallBack
    sqlite3_busy_handler(cw_database, &CWDBBusyCallBack, (void *)(cw_database));
    
    return YES;
}

+ (void)closeDB {
    if (cw_database) {
        sqlite3_close(cw_database);
        cw_database = nil;
    }
}


@end
