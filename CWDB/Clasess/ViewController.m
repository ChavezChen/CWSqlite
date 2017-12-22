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
    
//    [self testMultiThreadingSqliteMore];
}


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
//            NSLog(@"for-------------------------");
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
            for (int i = 1000; i < 1900; i++) {
                Student *stu = [self studentWithId:i];
                // 删除数据
                BOOL result = [CWSqliteModelTool deleteModel:stu uid:@"Chavez" targetId:nil];
                NSLog(@"delete result : %d   %zd",result,stu.stuId);
            }
        });
        
        
        
    });
    
}

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
