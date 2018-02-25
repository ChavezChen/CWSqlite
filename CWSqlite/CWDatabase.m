//
//  CWDatabase.m
//  CWDB
//
//  Created by ChavezChen on 2017/12/2.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "CWDatabase.h"
#import <sqlite3.h>

#define kCWDBCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject

//#define kCWDBCachePath @"/Users/mac/Desktop"

@interface CWDatabase ()

@end

@implementation CWDatabase

static sqlite3 *cw_database = nil;

static NSTimeInterval _startBusyRetryTime; // 第一次重试的时间

// 执行sql语句
+ (BOOL)execSQL:(NSString *)sql uid:(NSString *)uid {
    
    if (!cw_database) {
        if (![self openDB:uid]) {
            return NO;
        }
    }
    
    char *errmsg = nil;
    int result = sqlite3_exec(cw_database, sql.UTF8String, nil, nil, &errmsg);
    
    if (result != SQLITE_OK) {
        NSLog(@"exec SQL(%@) error : %s",sql,errmsg);
        sqlite3_free(errmsg);
        return NO;
    }
    return YES;
}

// 执行多个sql语句
+ (BOOL)execSqls:(NSArray <NSString *>*)sqls uid:(NSString *)uid {
    // 事务控制所有语句必须返回成功，才算执行成功
    [self beginTransaction:uid];
    
    for (NSString *sql in sqls) {
        BOOL result = [self execSQL:sql uid:uid];
        if (result == NO) {
            [self rollBackTransaction:uid];
            return NO;
        }
    }
    [self commitTransaction:uid];
    return YES;
}


// 查询
+ (NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid {
    // 1、打开数据库
    if (!cw_database) {
        if (![self openDB:uid]) {
            return nil;
        }
    }
    
    // 2、预执行语句
    sqlite3_stmt *ppStmt     = 0x00; //伴随指针
    if (sqlite3_prepare_v2(cw_database, sql.UTF8String, -1, &ppStmt, nil) != SQLITE_OK) {
        NSLog(@"查询准备语句编译失败");
        return nil;
    }
    // 3、绑定数据，因为我们的sql语句中不带有？用来赋值，所以不需要进行绑定
    // 4、执行遍历查询
    NSMutableArray *rowDicArray = [NSMutableArray array];
    while (sqlite3_step(ppStmt) == SQLITE_ROW) { // SQLITE_ROW表示还有下一条数据
        // 获取有多少列(也就是一条数据有多少个字段)
        int columnCount = sqlite3_column_count(ppStmt);
        // 存储一条数据的所有字段名与值 的字典
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionary];
        // 遍历数据库一条数据所有字段
        for (int i = 0; i < columnCount; i++) {
            // 获取字段名
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(ppStmt, i)];
            // 获取字段名对应的类型
            int type = sqlite3_column_type(ppStmt, i);
            // 获取对应的值
            id value = nil;
            switch (type) {
                case SQLITE_INTEGER:
                    value = @(sqlite3_column_int(ppStmt, i));
                    break;
                case SQLITE_FLOAT:
                    value = @(sqlite3_column_double(ppStmt, i));
                    
                    break;
                case SQLITE_BLOB: // 二进制
                    value = CFBridgingRelease(sqlite3_column_blob(ppStmt, i));
                    break;
                case SQLITE_NULL:
                    value = @"";
                    break;
                case SQLITE3_TEXT:
                    value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(ppStmt, i)];
                    break;
                    
                default:
                    break;
            }
            [rowDict setValue:value forKey:columnName];
        }
        [rowDicArray addObject:rowDict];
    }
    // 5、重制（省略）
    // 6、释放资源，关闭数据库
    sqlite3_finalize(ppStmt);
    
    return rowDicArray;
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

#pragma mark - 事务
+ (void)beginTransaction:(NSString *)uid {
    [self execSQL:@"BEGIN TRANSACTION" uid:uid];
}

+ (void)commitTransaction:(NSString *)uid {
     [self execSQL:@"COMMIT TRANSACTION" uid:uid];
}

+ (void)rollBackTransaction:(NSString *)uid {
     [self execSQL:@"ROLLBACK TRANSACTION" uid:uid];
}


@end
