//
//  ViewController.m
//  CWDB
//
//  Created by ChavezChen on 2017/11/29.
//  Copyright © 2017年 Chavez. All rights reserved.
//

#import "ViewController.h"
#import "CWSchool.h"

#import "CWSqliteModelTool.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSArray *dataSource;
@property (nonatomic,strong) UILabel *showLable;
@end

@implementation ViewController
{
    NSUInteger _showCount;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataSource = @[@"插入单条数据",@"异步插入单条数据",@"批量插入数据",@"异步批量插入数据",@"查询所有数据",@"异步查询所有数据",@"单条件查询(schoolId<2)",@"多条件查询(schoolId <2或者>=5)",@"自己写sql语句查询数据",@"删除表内所有数据",@"删除一条数据",@"单条件删除(schoolId小于2的)",@"多条件删除(schoolId小于2或大于5)",@"自己写sql语句删除数据"];
    [self setupShowLabel];
    
    NSLog(@"------SqliteDBPath:%@",NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject);
    
}

#pragma mark -  数据库方法调用演示

#pragma mark - 插入或者更新数据
#pragma mark 插入单条数据
- (void)inserModel{
    
    CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
    
    // 只要这一句代码即可
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:school];
//    [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil]; 与这样调用效果一样
    
    if (result) {
        [self showMessage:@"保存成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"保存失败。。。"];
    }
}

#pragma mark 异步插入单条数据
- (void)asyncInsertModel {
    
    [self showMessage:@"异步插入单条数据"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想女子学院"];
        
        // 如果先执行了上面inserModel方法，数据库里面存在一个id为9999的学校，则会自动将名字更新为 梦想女子学院,就是做更新操作了
        BOOL result = [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil];
//        [CWSqliteModelTool insertOrUpdateModel:school]; 与这样调用效果一样
        // 主线程进行UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [self showMessage:@"保存成功。。。快去数据库查看吧"];
            }else {
                [self showMessage:@"保存失败。。。"];
            }
        });
    });
}

#pragma mark 批量插入数据
- (void)insertGroupModels {
    
    NSMutableArray *schools = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        @autoreleasepool {
            CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想学院%zd",i]];
            [schools addObject:school];
        }
    }
    
    // 只要调用这个方法
//    [CWSqliteModelTool insertOrUpdateModels:schools]; 与这样调用效果一样
    BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil];
    
    if (result) {
        [self showMessage:@"保存成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"保存失败。。。"];
    }
}
#pragma mark 异步批量插入数据
- (void)asyncInsertGroupModels {
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    
    __block int successCount = 0;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *schools = [NSMutableArray array];
        for (int i = 0; i < 5; i++) {
            @autoreleasepool {
                // 注意：名字不同～
                CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想女子学院%zd",i]];
                [schools addObject:school];
            }
        }
        
        // 只要调用这个方法
//        [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil]; 与这样调用效果一样
        BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools];
        
        if (result) {
            successCount++;
        }
        dispatch_group_leave(group);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *schools = [NSMutableArray array];
        for (int i = 5; i < 10; i++) {
            @autoreleasepool {
                // 注意：名字不同～
                CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想女子学院%zd",i]];
                [schools addObject:school];
            }
        }
        
        // 只要调用这个方法
        BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil];
        
        if (result) {
            successCount++;
        }
        dispatch_group_leave(group);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *schools = [NSMutableArray array];
        for (int i = 10; i < 15; i++) {
            @autoreleasepool {
                // 注意：名字不同～
                CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想女子学院%zd",i]];
                [schools addObject:school];
            }
        }
        
        // 只要调用这个方法
        BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil];
        
        if (result) {
            successCount++;
        }
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 必须所有数据都插入成功，才提示成功.
        if (successCount == 3) {
            [self showMessage:@"所有线程数据保存成功。。。快去数据库查看吧"];
        }else {
            [self showMessage:@"有线程数据保存失败。。。"];
        }
    });
    
}


#pragma mark - 查询数据
#pragma mark 查询所有数据
- (void)queryAllModel {
    
    [self showMessage:@"开始查询"];
    //    NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class]]; 这样调用效果一样
    NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class] uid:nil targetId:nil];
    
    [self showMessage:[NSString stringWithFormat:@"数据库有%zd条数据",result.count]];
    
    NSLog(@"查询结果: %@",result);
    
}

#pragma mark 异步查询所有数据
- (void)asyncQueryAllModel {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //    NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class]]; 这样调用效果一样
        NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class] uid:nil targetId:nil];
        
        // 主线程进行UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self showMessage:[NSString stringWithFormat:@"数据库有%zd条数据",result.count]];
            NSLog(@"查询结果: %@",result);
        });
        
    });
}

#pragma mark 按单个条件查询
- (void)queryModelWithOneCondition {
    
    // 查询数据库内 schoolId < 2 的所有数据
//    NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] name:@"schoolId" relation:CWDBRelationTypeLess value:@(2)]; 这样调用效果一样
    
    NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] name:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
    
    [self showMessage:[NSString stringWithFormat:@"数据库有%zd条数据",result.count]];
    NSLog(@"查询结果: %@",result);
}

#pragma mark 按多个条件查询
- (void)queryModelWithConditions {
    
    // 查询数据库内 schoolId < 2 或者 schoolId >= 5 的所有数据
    NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(2),@(5)] isAnd:NO uid:nil targetId:nil];
    
    [self showMessage:[NSString stringWithFormat:@"数据库有%zd条数据",result.count]];
    NSLog(@"查询结果: %@",result);
}
#pragma mark 自己写sql语句查询
- (void)queryModelsWithSql {
    
    NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
    NSString *querySql = [NSString stringWithFormat:@"select * from %@ where schoolName = '梦想女子学院2'",tableName];
    
    NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] Sql:querySql uid:nil];
    
    [self showMessage:[NSString stringWithFormat:@"数据库有%zd条数据",result.count]];
    NSLog(@"查询结果: %@",result);
}

#pragma mark - 删除数据
#pragma mark 删除表内所有数据或者将表一起删除
- (void)deleteAllDataWithTable {
    // 最后一个参数传NO表示部保留表结构,将表结构一起删除,传YES表示保留表
    BOOL result = [CWSqliteModelTool deleteTableAllData:[CWSchool class] uid:nil targetId:nil isKeepTable:YES];
    
    if (result) {
        [self showMessage:@"删除成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"删除失败。。。"];
    }
}

#pragma mark 删除一条数据
- (void)deleteModel {
    CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
    // 这个方法，会根据传进来的模型的主键值去找到数据表里面的数据删除，与模型的其他字段值无关
    BOOL result = [CWSqliteModelTool deleteModel:school uid:nil targetId:nil];
    
    if (result) {
        [self showMessage:@"删除成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"删除失败。。。"];
    }
}
#pragma mark 按单个条件删除
- (void)deleteModelWithOneCondition {
    
    // 删除schoolId小于2的所有数据
    BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnName:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
    
    if (result) {
        [self showMessage:@"删除成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"删除失败。。。"];
    }
}

#pragma mark 按照多个条件删除
- (void)deleteModelWithCOnditions {
    
    // 删除schoolId小于2 或者 大于 5的所有数据
    BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(1),@(5)] isAnd:NO uid:nil targetId:nil];
    
    if (result) {
        [self showMessage:@"删除成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"删除失败。。。"];
    }
    
}
#pragma mark 自己写sql语句删除
- (void)deleteModelWithSql {
    
    // 如果保存模型的时候带有targetId，这里表名需要拼接targetId，格式为 [NSString stringWithFormat:@"%@%@",NSStringFromClass([CWSchool class]),targetId];
    NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where schoolName = '梦想女子学院2'",tableName];
    
    BOOL result = [CWSqliteModelTool deleteModelWithSql:deleteSql uid:nil];
    
    if (result) {
        [self showMessage:@"删除成功。。。快去数据库查看吧"];
    }else {
        [self showMessage:@"删除失败。。。"];
    }
}

#pragma mark - 快速获取一个模型
// 本来应该将方法封装到模型内，但是写到这更直观。。。就写这吧
- (CWSchool *)cwSchoolWithID:(int)schoolId name:(NSString *)schoolName {
    
    // 设计数据库的时候不建议这么设计，一个school表承载了太多的数据，最好班级一个表，学生一个表，老师一个表分开存储，存太多复杂的数据，数据库软件都卡住了。。。
    
    CWSchool *school = [[CWSchool alloc] init];
    school.schoolId = schoolId;
    school.schoolName = schoolName;
    school.grade = 100; // 学校评分位100分，这是一个非常完美的学校
    school.schoolUrl = [NSURL URLWithString:@"www.baidu.com"];
    school.schoolMaster = [self teacherWithID:99999 name:@"Chavez"]; // Chavez校长，就是我啦
    school.bestStudent = [self studentWithID:99999 name:@"关之琳"]; // 最优秀的学生是 关同学，毕竟保龄球技术666
    
    CWClass *bestClass = [self classWithID:99999 name:@"技巧班"]; //最优秀的班级是技巧班
    school.bestClass = bestClass;
    
    NSMutableArray *classes = [NSMutableArray array]; // 学校所有班级
    [classes addObject:bestClass]; // 添加最优秀的技巧班
    for (int i = 0; i < 2; i++) {
        @autoreleasepool {
            CWClass *cwClass = [self classWithID:i name:[NSString stringWithFormat:@"声音%d班",i]];
            [classes addObject:cwClass];
        }
    }
    school.classes = classes; // 3个班级，2个声音班 1个技巧班

    return school;
}

// 获取一个班级模型
- (CWClass *)classWithID:(int)clsaaId name:(NSString *)name {
    
    CWClass *c = [[CWClass alloc] init];
    c.className = name;
    c.classId = clsaaId;
    
    CWStudent *classMonitor = [self studentWithID:0 name:@"小泽***"];
    c.classMonitor = classMonitor; // 小泽***班长
    
    NSMutableArray *students = [NSMutableArray array]; // 学生们
    [students addObject:classMonitor]; // 添加班长
    for (int i = 1; i < 4; i++) {
        @autoreleasepool {
            CWStudent *stu = [self studentWithID:i name:[NSString stringWithFormat:@"松岛%d同学",i]];
            [students addObject:stu];
        }
    }
    c.students = students; // 班级里面有49位松同学以及一位小泽班长
    
    
    CWTeacher *classTeacher = [self teacherWithID:0 name:@"苍老师"];   // 班主任是 苍老师！！！！！
    c.classTeacher = classTeacher;
    
    NSMutableArray *teachers = [NSMutableArray array]; // 老师们
    [teachers addObject:classTeacher]; // 添加班主任
    for (int i = 1; i < 2; i++) {
        @autoreleasepool {
            CWTeacher *teacher = [self teacherWithID:i name:[NSString stringWithFormat:@"林志玲%d",i]];
            [teachers addObject:teacher];
        }
    }
    c.teachers = teachers; // 班级有2位林老师 以及一位苍老师
    
    return c;
}

// 获取一个女老师
- (CWTeacher *)teacherWithID:(int)teachId name:(NSString *)name {
    
    CWTeacher *teacher = [[CWTeacher alloc] init];
    teacher.teachId = teachId;
    teacher.name = name;
    teacher.gender = @"女"; // 全是女老师
    teacher.age = 28; // 全是御姐女老师
    teacher.height = 155; // 全是小个子女老师
    teacher.weight = 100; // 额。。相对身高有点重但是一定不是胖！为啥捏？你猜😁。。其中一个老师是苍老师
    teacher.photo = [UIImage imageNamed:@"001"]; // 女老师的职业全身照
    teacher.subjects = @"技巧";  // 上课教的是 技巧～，咦。。啥技巧
    
    return teacher;
}

// 获取一个女同学
- (CWStudent *)studentWithID:(int)stuId name:(NSString *)name {
    
    CWStudent *student = [[CWStudent alloc] init];
    student.stuId = stuId;
    student.name = name;
    student.gender = @"女";    // 全是女同学
    student.age = 20;         // 全是20岁，花一般年纪的女同学
    student.personality = @"性格温和，乖巧，听话"; // 全是性格温和乖巧听话的花季女同学
    student.height = 168.5;   // 全是高挑的花季女同学
    student.weight = 100;     // 全是好身材的花季女同学（体重不过百，不是平胸就是矮，明显咱们学校的妹子体重都过100了）
    student.photo = [UIImage imageNamed:@"001"]; // 女同学没有经过美颜、PS、滤镜的证件照
    student.scoreDict = @{ @"声音":@(100) , @"技巧":@(99) }; // 噢。。这个很重要，这个学校考核的不是数理化而是考核声音和技巧。。。。这。。这是音乐学院嘛😁。
    
    return student;
}


#pragma mark - UI设置，与本测试无关!!!!
- (void)setupShowLabel {
    _showLable = [[UILabel alloc] initWithFrame:CGRectZero];
    _showLable.textColor = [UIColor redColor];
    _showLable.backgroundColor = [UIColor lightGrayColor];
    _showLable.numberOfLines = 0;
    _showLable.font = [UIFont systemFontOfSize:30];
    _showLable.frame = CGRectMake(0, 0, 300, 300);
    _showLable.center = CGPointMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) / 2);
    _showLable.hidden = YES;
    [self.view addSubview:_showLable];
}

- (void)showMessage:(NSString *)message {
    _showCount++;
    _showLable.text = message;
    _showLable.hidden = NO;
    NSLog(@"----%@",message);
    self.tableView.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (--_showCount == 0) {
            _showLable.hidden = YES;
            self.tableView.userInteractionEnabled = YES;
        }
    });
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd.%@",indexPath.row,_dataSource[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
            [self inserModel];
            break;
        case 1:
            [self asyncInsertModel];
            break;
        case 2:
            [self insertGroupModels];
            break;
        case 3:
            [self asyncInsertGroupModels];
            break;
        case 4:
            [self queryAllModel];
            break;
        case 5:
            [self asyncQueryAllModel];
            break;
        case 6:
            [self queryModelWithOneCondition];
            break;
        case 7:
            [self queryModelWithConditions];
            break;
        case 8:
            [self queryModelsWithSql];
            break;
        case 9:
            [self deleteAllDataWithTable];
            break;
        case 10:
            [self deleteModel];
            break;
        case 11:
            [self deleteModelWithOneCondition];
            break;
        case 12:
            [self deleteModelWithCOnditions];
            break;
        case 13:
            [self deleteModelWithSql];
            break;
        default:
            break;
    }
    
}

@end
