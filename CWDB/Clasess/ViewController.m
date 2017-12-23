//
//  ViewController.m
//  CWDB
//
//  Created by ChavezChen on 2017/11/29.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "ViewController.h"
#import "CWSqliteModelTool.h"
#import "Student.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self testGroupInsert];
    
//    [self testMultiThreadingSqliteMore1];
//    [self testQuery];
}

#pragma mark - 测试批量插入数据
- (void)testGroupInsert {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 1; i < 2000; i++) {
        Student *stu = [self studentWithId:i];
        [arr addObject:stu];
    }
    NSLog(@"开始插入数据");
    // 2017-12-23 16:25:46.145023+0800 CWDB[14678:1604328] 开始插入数据
    BOOL result = [CWSqliteModelTool insertOrUpdateModels:arr uid:@"Chavez" targetId:nil];
    NSLog(@"---%zd---插入结束",result);
    // 2017-12-23 16:25:48.466352+0800 CWDB[14678:1604328] ---1---插入结束
    // 使用批量插入的方法 插入2000条数据，总共耗时2.3秒
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"---------------组1开始");
        // 2017-12-23 16:25:48.466587+0800 CWDB[14678:1604407] ---------------组1开始
        for (int i = 2000; i < 4000; i++) {
            @autoreleasepool {
                Student *stu = [self studentWithId:i];
                BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"result : %d   %zd",result,stu.stuId);
            }
        }
        NSLog(@"---------------组1结束");
        // 2017-12-23 16:25:56.247631+0800 CWDB[14678:1604407] ---------------组1结束
        // 自行遍历的方式插入2000条数据，总共耗时8秒(且要自行增加autoreleasepool释放临时变量)
    });
    
}


#pragma mark - for循环未使用autoreleasepool的多线程操作
- (void)testMultiThreadingSqliteMore {
    
    dispatch_queue_t queue1 = dispatch_queue_create("CWDBTest1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_queue_create("CWDBTest2", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue3 = dispatch_queue_create("CWDBTest3", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue4 = dispatch_queue_create("CWDBTest4", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    
    dispatch_async(queue1, ^{
        for (int i = 1; i < 1000; i++) {
            Student *stu = [self studentWithId:i];
            BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
            NSLog(@"result : %d   %zd",result,stu.stuId);
        }
        NSLog(@"---------------组1结束");
        dispatch_group_leave(group);
    });
    
    dispatch_async(queue2, ^{
        for (int i = 1000; i < 2000; i++) {
            Student *stu = [self studentWithId:i];
            BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
            NSLog(@"result : %d   %zd",result,stu.stuId);
        }
        NSLog(@"---------------组2结束");
        dispatch_group_leave(group);
    });
    
    dispatch_async(queue3, ^{
        for (int i = 2000; i < 3000; i++) {
            Student *stu = [self studentWithId:i];
            BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
            NSLog(@"result : %d   %zd",result,stu.stuId);
        }
        NSLog(@"---------------组3结束");
        dispatch_group_leave(group);
    });
    
    // 当前面3个队列的任务都完成，则调用此通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"----------------------插入结束");
        dispatch_async(queue4, ^{
            for (int i = 1; i < 1000; i++) {
                Student *stu = [self studentWithId:i];
                // 删除数据
                BOOL result = [CWSqliteModelTool deleteModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"delete result : %d   %zd",result,stu.stuId);
            }
        });
        dispatch_async(queue1, ^{
            for (int i = 2000; i < 3000; i++) {
                Student *stu = [self studentWithId:i];
                // 删除数据
                BOOL result = [CWSqliteModelTool deleteModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"delete result : %d   %zd",result,stu.stuId);
            }
        });
        
        dispatch_async(queue2, ^{
            // 删除数据
            BOOL result = [CWSqliteModelTool deleteModel:[Student class] columnNames:@[@"stuId",@"stuId"] relations:@[@(CWDBRelationTypeMoreEqual),@(CWDBRelationTypeLess)] values:@[@(1000),@(1900)] isAnd:YES uid:@"Chavez" targetId:nil];
            NSLog(@"delete result : %d  1000-1900",result);
        });
    });
    
}

#pragma mark - for循环使用autoreleasepool的多线程操作
- (void)testMultiThreadingSqliteMore1 {
    
    dispatch_queue_t queue1 = dispatch_queue_create("CWDBTest1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_queue_create("CWDBTest2", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue3 = dispatch_queue_create("CWDBTest3", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue4 = dispatch_queue_create("CWDBTest4", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);

    dispatch_async(queue1, ^{
        for (int i = 1; i < 1000; i++) {
            @autoreleasepool {
                Student *stu = [self studentWithId:i];
                BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"result : %d   %zd",result,stu.stuId);
            }
        }
        NSLog(@"---------------组1结束");
        dispatch_group_leave(group);
    });
    
    dispatch_async(queue2, ^{
        for (int i = 1000; i < 2000; i++) {
            @autoreleasepool {
                Student *stu = [self studentWithId:i];
                BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"result : %d   %zd",result,stu.stuId);
            }
        }
        NSLog(@"---------------组2结束");
        dispatch_group_leave(group);
    });

    dispatch_async(queue3, ^{
        for (int i = 2000; i < 3000; i++) {
            @autoreleasepool {
                Student *stu = [self studentWithId:i];
                BOOL result = [CWSqliteModelTool insertOrUpdateModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"result : %d   %zd",result,stu.stuId);
            }
        }
        NSLog(@"---------------组3结束");
        dispatch_group_leave(group);
    });


    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"----------------------插入结束");
        dispatch_async(queue4, ^{
            for (int i = 1; i < 1000; i++) {
                @autoreleasepool {
                    Student *stu = [self studentWithId:i];
                    // 删除数据
                    BOOL result = [CWSqliteModelTool deleteModel:stu uid:@"Chavez" targetId:nil];
                    NSLog(@"delete result : %d   %zd",result,stu.stuId);
                }
            }
        });
        dispatch_async(queue1, ^{
            // 遍历删除数据
            for (int i = 2000; i < 3000; i++) {
                @autoreleasepool {
                    Student *stu = [self studentWithId:i];
                    // 删除数据
                    BOOL result = [CWSqliteModelTool deleteModel:stu uid:@"Chavez" targetId:nil];
                    NSLog(@"delete result : %d   %zd",result,stu.stuId);
                }
            }
        });
        
        dispatch_async(queue2, ^{
            // 传两个条件删除数据
            BOOL result = [CWSqliteModelTool deleteModel:[Student class] columnNames:@[@"stuId",@"stuId"] relations:@[@(CWDBRelationTypeMoreEqual),@(CWDBRelationTypeLess)] values:@[@(1000),@(1900)] isAnd:YES uid:@"Chavez" targetId:nil];
            NSLog(@"delete result : %d  1000-1900",result);
        });
        
        
        
    });
    
}

#pragma mark - 测试查询图片与NSData
- (void)testQuery {
    NSArray *arr = [CWSqliteModelTool querModels:[Student class] name:@"stuId" relation:CWDBRelationTypeEqual value:@(1900) uid:@"Chavez" targetId:nil];
    Student *stu = arr.firstObject;
    UIImageView *imageV1 = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    imageV1.contentMode = UIViewContentModeScaleAspectFit;
    imageV1.image = [UIImage imageWithData:stu.data];
    [self.view addSubview:imageV1];
    
    UIImageView *imageV2 = [[UIImageView alloc] initWithFrame:CGRectMake(100, 200, 100, 100)];
    imageV2.contentMode = UIViewContentModeScaleAspectFit;
    imageV2.image = stu.image;
    [self.view addSubview:imageV2];
    
}

#pragma mark - 快速获取一个模型
- (Student *)studentWithId:(int)stuId {
    School *school1 = [[School alloc] init];
    school1.name = @"北京大学";
    school1.schoolId = 2;
    
    School *school = [[School alloc] init];
    school.name = @"清华大学";
    school.schoolId = 1;
    school.school1 = school1;
    
    Student *stu = [[Student alloc] init];
    stu.stuId = stuId;
    stu.name = @"Baidu";
    stu.age = 100;
    stu.height = 190;
    stu.weight = 140;
    stu.dict = @{@"name" : @"chavez"};
    // 字典嵌套模型
    stu.dictM = [@{@"清华大学" : school , @"北京大学" : school1 , @"money" : @(100)} mutableCopy];
    // 数组嵌套字典，字典嵌套模型
    stu.arrayM = [@[@"chavez",@"cw",@"ccww",@{@"清华大学" : school}] mutableCopy];
    // 数组嵌套模型
    stu.array = @[@(1),@(2),@(3),school,school1];
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:@"attributedStr,attributedStr"];
    stu.attributedString = attributedStr;
    // 模型嵌套模型
    stu.school = school;
    UIImage *image = [UIImage imageNamed:@"001"];
    NSData *data = UIImageJPEGRepresentation(image, 1);
    stu.image = image;
    stu.data = data;
    
    return stu;
}

@end
