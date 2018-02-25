# CWDB 
## 架构
类名 | 作用
-------- | ---
CWModelProtocol.h | 需要遵守以及实现的协议方法（用户关注）
CWSqliteModelTool.h、CWSqliteModelTool.m | 本库操作数据库的所有API（用户关注）
CWDatabase.h、CWDatabase.m | 直接调用sqlite底层API的类
CWModelTool.h、CWModelTool.m  | 处理模型的工具类
CWSqliteTableTool.h、CWSqliteTableTool. | 处理数据库表的工具类
## 前言
首先介绍一下我们的功能：**嗯。。。一句话：简单、实用。** 


![效果](https://github.com/ChavezChen/CWDB/blob/master/lalala.gif)
- **直接**: 调用sqlite原生API操作数据库，没有中间框架。
- **易用**: 一行代码实现数据库增删查改操作。
- **多元**: 支持所有基本数据类型、集合类型以及自定义模型。
- **智能**: 一行代码，智能实现插入、更新、升级、迁移数据。
- **强大**: 0代码支持数组嵌套模型、嵌套字典，字典嵌套模型等相互嵌套。
- **灵活**: 支持多种查询、删除操作，支持使用sql语句查询、删除。
- **还原**: 存入数据库时为A模型，查询的数据一定还给你A模型。
- **安全**: 多线程安全可靠。

**我们支持的数据类型有**：
```objective-c
所有的基本数据类型（int，float），NSNumber，NSArray，NSMutableArray，NSDictionary，NSMutableDictionary，
UIImage，NSURL，UIColor，NSSet，NSRange，NSAttributedString，NSData，自定义模型，以及数组、字典、模型相互嵌套。
```
## 来一句洋文，How to use？
### 第一步，给项目添加sqlite3.0.tbd依赖库,将CWDB拖进你的项目或者使用cocoapods的方式
```objective-c
platform :ios, '8.0'

target '工程名称' do
pod ‘CWDB’, '~> 1.6.0’
end
/* 如果搜索不到
1、执行rm ~/Library/Caches/CocoaPods/search_index.json 删除索引的缓存再搜索，还不行执行第2步更新cocoapods
2、执行 pod repo update --verbose 更新成功之后就没问题了
*/
```
### 第二步，需要保存入数据库的模型Import并遵守CWModelProtocol协议，实现+ (NSString *)primaryKey；方法返回主键信息，主键为数据的唯一标识，如
 ```objective-c

// 实现协议方法
@implementation CWSchool
// 以schoolId为主键返回！
+ (NSString *)primaryKey {
    return @"schoolId";
}

@end
 ```
 
### 第三步，为所欲为之为所欲为操作数据库～

- **插入或者更新数据**
```objective-c
// 使用工厂方法创建的shool模型
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
    
// 调用保存或者更新方法
BOOL result = [CWSqliteModelTool insertOrUpdateModel:school];
// 下面这个方法uid为userId，对应数据库的名字，targetId为目标ID，与数据库表名相关，可以传nil，下面我会详细讲解这两个参数的用途。
// BOOL result = [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil]; 这样调用也是一样的
```
- **异步插入或更新数据**
```objective-c
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想女子学院"];
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:school];
//    BOOL result = [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil];这样调用也是一样的
});
```
**关于数据库升级以及数据库迁移**，我们先模拟一个场景，比如我存在数据库的数据为聊天记录Message，里面有10个成员变量，有一天，业务的提升，我要在Message里面多加一个成员变量，比如新增一个成员变量用来标记是否是撤回的消息，这个时候由于数据库的表结构固定死了没这个字段，插入数据会失败。**所以我们要进行数据库升级，并且要将之前的数据都保留下来，这么麻烦？这个要怎么做呢？这里压根不需要你思考这个问题，我们作为一个负责任的男人，我们很负责任的告诉你，假如你的Message模型增加了1个两个10个成员变量，你只管加，加了之后只管调用上面的方法存，数据的升级以及迁移我们默认会帮你完成！！！** 

当然，还有另外一种场景，**字段改名**比如你的Message模型里面有10个成员变量，其中有一个成员变量为 VoiceUrl（语音路径），有一天脑袋被门夹了一下，你们要把VoiceUrl改为VoicePath，并且以前存在数据库的值也不能删除，怎么办？难道你只能说 **what‘s the fuck**？？这里就用到我们的字段改名，非常的方便，首先你尽管在模型里面将VoiceUrl改为VoicePath，改了之后只需要在模型里实现我们CWModelProtocol协议的另一个方法+ (NSDictionary *)newNameToOldNameDic告诉我你要使用哪一个值来替换原来的值即可。直接上用例:
```objective-c
// 字段改名，实现这个方法，key 为 新的成员变量名称，value为老的成员变量名称，实现之后我们会帮你把之前VoiceUrl下面的值存到VoicePath下！
+ (NSDictionary *)newNameToOldNameDic {
    return @{@"VoicePath" : @"VoiceUrl"};
}
```
**最后一个场景**，假如你的模型有10个成员变量,但是其中有几个成员变量我不希望存到数据库里面，怎么办？？同样的，只要在模型里实现我们CWModelProtocol协议的方法+ (NSArray *)ignoreColumnNames告诉我哪几个字段你不想存知道数据库即可,直接上用例
```objective-c
// 不想将模型里面的height 以及 weight 保存到数据库,在模型的.m内实现这个方法
+ (NSArray *)ignoreColumnNames {
    return @[@"height",@"weight"];
}
```
### 其他方法使用,每个方法对应有简易方法和完整方法
- **批量插入或者更新数据**
```objective-c
// 生成5个学校模型保存在数组
NSMutableArray *schools = [NSMutableArray array];
for (int i = 0; i < 5; i++) {
    CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想学院%zd",i]];
    [schools addObject:school];
}

// 第一个参数数组内的元素必须全部是同一类型，异步和单个插入类似
BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil];
// BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools]; 这样调用是同样的效果

```
- **查询数据库表内所有数据**
```objective-c
// 查询CWShool表里的所有数据，uid对应数据库，targetId和表名姓关。返回的数组里面的元素都是CWSchool的模型。
NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class] uid:nil targetId:nil];
// NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class]]; 这样调用是同样的效果
```
- **按照单个条件查询数据表内的数据**
```objective-c
// 查询CWSchool数据表内 schoolId < 2 的所有数据,详细讲解可以看代码里的API注释
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] name:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
// NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] name:@"schoolId" relation:CWDBRelationTypeLess value:@(2)]; 这样调用是同样的效果
```
- **按照多个条件查询**
```objective-c
// 查询CWSchool数据表内 schoolId < 2 或者 schoolId >= 5 的所有数据,详细讲解可以看代码里的API注释
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(2),@(5)] isAnd:NO uid:nil targetId:nil];
// NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(2),@(5)] isAnd:NO]; 这样调用是同样的效果
```
- **自己写sql语句查询**
```objective-c
NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
// 查询学校名字为‘梦想女子学院2’的所有数据
NSString *querySql = [NSString stringWithFormat:@"select * from %@ where schoolName = '梦想女子学院2'",tableName];
    
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] Sql:querySql uid:nil];

```
- **删除一条数据**
```objective-c
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
// 这个方法，会根据传进来的模型的主键值去找到数据表里面的数据删除，与模型的其他字段值无关
BOOL result = [CWSqliteModelTool deleteModel:school uid:nil targetId:nil];
// BOOL result = [CWSqliteModelTool deleteModel:school]; 这样调用是同样的效果
```
- **按照单个条件删除**
```objective-c
// 删除schoolId小于2的所有数据
BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnName:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
// BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnName:@"schoolId" relation:CWDBRelationTypeLess value:@(2)]; 这样调用是同样的效果
```
- **按照多个条件删除**
```objective-c
// 删除schoolId小于2 或者 大于5的所有数据,详细解释请看代码API注释
BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(1),@(5)] isAnd:NO uid:nil targetId:nil];
```
- **自己写sql语句删除**
```objective-c
// 如果保存模型的时候带有targetId，这里表名需要拼接targetId，格式为 [NSString stringWithFormat:@"%@%@",NSStringFromClass([CWSchool class]),targetId];
NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where schoolName = '梦想女子学院2'",tableName];

BOOL result = [CWSqliteModelTool deleteModelWithSql:deleteSql uid:nil];
```

- **删除表内所有数据或者直接将表以及表内数据全部删除**
```objective-c
// 最后一个参数传NO表示不保留表结构,将表结构一起删除,传YES表示保留表
BOOL result = [CWSqliteModelTool deleteTableAllData:[CWSchool class] uid:nil targetId:nil isKeepTable:YES];

```
### 关于插入函数方法的部分讲解：首先我要对这个方法做一部分介绍（文字太长可以跳过）：我们在插入数据这个方法里面直接承载的业务有：插入模型，更新模型，数据库升级，数据迁移。这四个业务我们都智能帮你封装在一个方法内部，你不需要去处理其中的任何一种单独情况！
有人肯定会问，**既然保存和更新都是调用这个方法，是以什么为标准来判断是保存还是更新的呢**？我们会根据你传入的模型的主键值来判断数据库表格是否已经存在对应的数据，如果数据库表格存在主键同样的数据，我们直接将旧的数据替换掉。

### 其次，既然uid与targetId都可以传nil，为什么要设计这两个麻烦的参数，这就和我之前的IM经验相关了。有时候不是为了设计API而设计，而是为了便于设计整个数据库架构而设计。

**uid：** 有一种场景，在做IM的时候，一个手机APP可能登陆不同的账号，这个时候，我们希望将不同账号的信息，分为不同的数据库去保存，比如张三登陆了，我们以张三.db 新建一个数据库（之前没有数据库的情况下），李四登陆了，我们再以李四.db 新建一个数据库，他们的信息分别存在自己的数据库里，这样设计有什么好处？我们可以把各个用户的聊天记录以及相关信息分别存储，方便管理以及查询，比如你去银行存钱，你的钱一定是存在你的银行卡里面，而不会是你、我、他的钱都存在同一个银行卡里面，所以我们这里要传uid，用来分辨是哪一个用户的数据库。如果不传，会默认为CWDB公共数据库。

**targetId：** 首先我们要说明，我们的数据库表名是以模型类型的名称来命名的。在大部分情况下，这样是没有问题的，但是，同样是在IM的场景下，比如我和张三聊天，那么我和张三的聊天记录会以Message的模型存在Message的表里面，如果我和李四聊天，那么我和李四的聊天记录也存在Message的表里面吗？这样数据库的数据会非常混乱，因为你可能会和更多的人聊天，那Message这个表会非常臃肿，所以我们引入targetId目标ID这一参数，我们的表名就会是《模型名称+targetId》，以张三为例，他的聊天记录表就是Message张三，李四就是Message李四。**如果你的数据库里面一个模型只需要统一管理一个表，那么你传nil即可**。

### 如何使用介绍完了，如果上面的API有不能满足你需求的场景，欢迎向我抛issue，我会及时响应并且增加对应功能，如果你在使用过程中发现问题，也欢迎提issue给我，issue的大门永远为你敞开～已经支持cocoapods。 如果你想自己封装一个数据库，但是没有学习的资料，你可以前往我下面的文章传送门进行了解，基本上每一个大的功能点都记录在文章里面，最关键的，如果你觉得对你有所帮助，请赐我一个star！！



## 实现细节

[从0开始弄一个面向OC数据库（一）](https://juejin.im/post/5a3136ab51882535cd4ad579) 

[从0开始弄一个面向OC数据库（二）](https://juejin.im/post/5a3137216fb9a0452b493caa) 

[从0开始弄一个面向OC数据库（三）](https://juejin.im/post/5a31ea18f265da43333e6a1c) 

[从0开始弄一个面向OC数据库（四）](https://juejin.im/post/5a3a158d6fb9a045211eda38) 

[从0开始弄一个面向OC数据库（五）](https://juejin.im/post/5a3e367f5188257c4d1b5e75) 

[从0开始弄一个面向OC数据库--终结篇](https://juejin.im/post/5a433e1f6fb9a04524061b12) 
