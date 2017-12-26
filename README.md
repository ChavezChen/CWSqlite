# CWDB 一行代码操作数据库（貌似大家都是这么说的。。。）

## 前言
大约在公元19..好吧，之前，做过一段时间的IMSDK的开发，数据库也算其中一个比较重要的功能，由于当时属于一个小白阶段，我只能围观围观代码，一直想着自己有一天能封装一个数据库，加上最近学了一丢丢数据库的东西，就尝试着做了一下，为了不让计划太监，我特意每实现一个细节都用文章记录下来，毕竟自制力不一定靠谱。最终。做出来了，做出来的效果我基本满意，首先介绍一下我们的功能：**嗯。。。一句话：简单、实用。** 
- 增删查改通通实现，一行代码，你给我一个模型，我还你一个数据库。
- 多类型支持存储，所有基本数据类型（int，float...），NSArray，NSMutableArray，NSDictionary，NSMutableDictionary，UIImage，NSURL，UIColor，NSSet，NSRange，NSAttributedString，NSData，自定义模型以及数组、字典、模型相互嵌套。一行代码，你给我一个模型，我替你保存整个世界。
- 多类型支持查询，一行代码，无缝查询，你存我这的是什么，我还你的就是什么，你给我一个西瓜，我一定不会给你一颗芝麻，还你的一定是西瓜，这是男人的义务。
- 多线程安全，当有一天你左手给我一个西瓜，右手给我一个芝麻，我一定会帮你把西瓜和芝麻都存好，不会存了芝麻丢了西瓜,这是男人的责任。
- 一统新增与修改两大操作，一行代码，你传我一个模型，我帮你分辨需要插入还是更新，这是男人的第六感，我懂你～
- 秘密升级数据库并迁移数据，一行代码，你给我一个模型，我帮你升级并迁移数据库，这是男人的第七感，我晓得你～
- 然后还有什么能吹的么？暂时就这些吧。

## 来一句洋文，How to use？

### 第一步，需要保存入数据库的模型Import并遵守<CWModelProtocol>协议，实现+ (NSString *)primaryKey；方法返回主键信息，主键为数据的唯一标识，如
 ```
  // 一个学校模型，遵守CWModelProtocol协议
@interface CWSchool : NSObject<CWModelProtocol>

@property (nonatomic,assign) int schoolId; // 学校ID
@property (nonatomic,assign) float grade; // 学校评分
@property (nonatomic,copy) NSString *schoolName; // 学校名称
@property (nonatomic,strong) NSURL *schoolUrl; // 学校主页地址
@end

// 实现协议方法
@implementation CWSchool
// 以schoolId为主键返回！
+ (NSString *)primaryKey {
    return @"schoolId";
}

@end
 ```
 
### 第二步，一行代码随心所欲来操作你的数据库吧～

- 插入或者更新数据
```
// 使用工厂方法创建的shool模型
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
    
// 调用保存或者更新方法,uid为userId，对应数据库的名字，targetId为目标ID，与数据库表名相关，可以传nil，下面我会详细讲解这两个参数的用途。
BOOL result = [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil];

```
- 异步插入或更新数据
```
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想女子学院"];
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    BOOL result = [CWSqliteModelTool insertOrUpdateModel:school uid:nil targetId:nil];
});
```
首先有人肯定会问，**既然保存和更新都是调用这个方法，是以什么为标准来判断是保存还是更新的呢**？我们会根据你传入的模型的主键值来判断数据库表格是否已经存在对应的数据，如果数据库表格存在主键同样的数据，我们直接将旧的数据替换掉。

其次，既然uid与targetId都可以传nil，为什么要设计这两个麻烦的参数，这就和我之前的IM经验相关了。

**uid：** 有一种场景，在做IM的时候，一个手机APP可能登陆不同的账号，这个时候，我们希望将不同账号的信息，分为不同的数据库去保存，比如张三登陆了，我们以张三.db 新建一个数据库（之前没有数据库的情况下），李四登陆了，我们再以李四.db 新建一个数据库，他们的信息分别存在自己的数据库里，这样设计有什么好处？我们可以把各个用户的聊天记录以及相关信息分别存储，方便管理以及查询，比如你去银行存钱，你的钱一定是存在你的银行卡里面，而不会是你、我、他的钱都存在同一个银行卡里面，所以我们这里要传uid，用来分辨是哪一个用户的数据库。如果不传，会默认为CWDB公共数据库。

**targetId：** 首先我们要说明，我们是以模型类型的名称来命名数据库的表名，在大部分情况下，这样是没有问题的，但是，同样是在IM的场景下，比如我和张三聊天，那么我和张三的聊天记录会以Message的模型存在Message的表里面，如果我和李四聊天，那么我和李四的聊天记录也存在Message的表里面吗？这样数据库的数据会非常混乱，因为你可能会和更多的人聊天，那Message这个表会非常臃肿，所以我们引入targetId目标ID这一参数，我们的表名就会是《模型名称+targetId》，以张三为例，他的聊天记录表就是Message张三，李四就是Message李四。**如果你的数据库里面一个模型只需要统一管理一个表，那么你传nil即可**。

再次，关于数据库升级以及数据库迁移以及字段改名，我们先模拟一个场景，比如我存在数据库的数据为聊天记录Message，里面有10个成员变量，有一天，业务的提升，我要在Message里面多加一个成员变量，比如新增一个成员变量用来标记是否是撤回的消息，这个时候由于数据库的表结构固定死了没这个字段，**我们将要进行数据库升级，并且要将之前的数据都保留下来，这么麻烦？这个要怎么做呢？这里压根不需要你思考这个问题，我们作为一个负责任的男人，我们很负责任的告诉你，假如你的Message模型增加了1个两个10个成员变量，你只管加，加了之后只管调用上面的方法存，数据的升级以及迁移我们默认会帮你完成！！！** 

当然，还有另外一种场景，比如你的Message模型里面有10个成员变量，其中有一个成员变量为 VoiceUrl（语音路径），有一天脑袋被门夹了一下，你们要把VoiceUrl改为VoicePath，并且以前存在数据库的值也不能删除，怎么办？难道你只能说 **what‘s the fuck**？？这里就用到我们的字段改名，非常的方便，首先你尽管在模型里面将VoiceUrl改为VoicePath，然后你改了之后需要在模型里实现我们CWModelProtocol协议的另一个方法，直接上用例:
```
// 字段改名，实现这个方法，key 为 新的成员变量名称，value为老的成员变量名称，实现之后我们会帮你把之前VoiceUrl下面的值存到VoicePath下！
+ (NSDictionary *)newNameToOldNameDic {
    return @{@"VoicePath" : @"VoiceUrl"};
}
```
**最后一个场景**，假如你的模型有10个成员变量,但是其中有几个成员变量我不希望存到数据库里面，怎么办？？同样的，在模型里实现我们CWModelProtocol协议的方法,直接上用例
```
// 不想将模型里面的height 以及 weight 保存到数据库,在模型的.m内实现这个方法
+ (NSArray *)ignoreColumnNames {
    return @[@"height",@"weight"];
}
```
**其他方法使用**
- 批量插入或者更新数据
```
// 生成5个学校模型保存在数组
NSMutableArray *schools = [NSMutableArray array];
for (int i = 0; i < 5; i++) {
    @autoreleasepool {
        CWSchool *school = [self cwSchoolWithID:i name:[NSString stringWithFormat:@"梦想学院%zd",i]];
        [schools addObject:school];
    }
}

// 第一个参数数组内的元素必须全部是同一类型，异步和单个插入类似
BOOL result = [CWSqliteModelTool insertOrUpdateModels:schools uid:nil targetId:nil];
```
- 查询数据库表内所有数据
```
// 查询CWShool表里的所有数据，uid对应数据库，targetId和表名姓关。返回的数组里面的元素都是CWSchool的模型。
NSArray *result = [CWSqliteModelTool queryAllModels:[CWSchool class] uid:nil targetId:nil];
```
- 按照单个条件查询数据表内的数据
```
// 查询CWSchool数据表内 schoolId < 2 的所有数据,详细讲解可以看代码里的API注释
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] name:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
```
- 按照多个条件查询
```
// 查询CWSchool数据表内 schoolId < 2 或者 schoolId >= 5 的所有数据,详细讲解可以看代码里的API注释
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(2),@(5)] isAnd:NO uid:nil targetId:nil];
```
- 自己写sql语句查询
```
NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
// 查询学校名字为‘梦想女子学院2’的所有数据
NSString *querySql = [NSString stringWithFormat:@"select * from %@ where schoolName = '梦想女子学院2'",tableName];
    
NSArray *result = [CWSqliteModelTool queryModels:[CWSchool class] Sql:querySql uid:nil];

```
- 删除一条数据
```
CWSchool *school = [self cwSchoolWithID:9999 name:@"梦想学院"];
// 这个方法，会根据传进来的模型的主键值去找到数据表里面的数据删除，与模型的其他字段值无关
BOOL result = [CWSqliteModelTool deleteModel:school uid:nil targetId:nil];
```
- 按照单个条件删除
```
// 删除schoolId小于2的所有数据
BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnName:@"schoolId" relation:CWDBRelationTypeLess value:@(2) uid:nil targetId:nil];
```
- 按照多个条件删除
```
// 删除schoolId小于2 或者 大于5的所有数据,详细解释请看代码API注释
BOOL result = [CWSqliteModelTool deleteModels:[CWSchool class] columnNames:@[@"schoolId",@"schoolId"] relations:@[@(CWDBRelationTypeLess),@(CWDBRelationTypeMoreEqual)] values:@[@(1),@(5)] isAnd:NO uid:nil targetId:nil];
```
- 自己写sql语句删除
```
// 如果保存模型的时候带有targetId，这里表名需要拼接targetId，格式为 [NSString stringWithFormat:@"%@%@",NSStringFromClass([CWSchool class]),targetId];
NSString *tableName = [NSString stringWithFormat:@"%@",NSStringFromClass([CWSchool class])];
NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where schoolName = '梦想女子学院2'",tableName];

BOOL result = [CWSqliteModelTool deleteModelWithSql:deleteSql uid:nil];
```

- 删除表内所有数据或者直接将表以及表内数据全部删除
```
// 最后一个参数传NO表示部保留表结构,将表结构一起删除,传YES表示保留表
BOOL result = [CWSqliteModelTool deleteTableAllData:[CWSchool class] uid:nil targetId:nil isKeepTable:YES];

```

### 如何使用介绍完了，如果上面的API有不能满足你需求的场景，欢迎向我抛issue，我会及时响应并且增加对应功能，如果你在使用过程中发现问题，也欢迎提issue给我，issue的大门永远为你敞开～ 如果你想自己封装一个数据库，但是没有学习的资料，你可以前往我下面的文章传送门进行了解，基本上每一个大的功能点都记录在文章里面，最关键的，如果你觉得对你有所帮助，请赐我一个star！！

## 实现细节

[从0开始弄一个面向OC数据库（一）](https://juejin.im/post/5a3136ab51882535cd4ad579) 

[从0开始弄一个面向OC数据库（二）](https://juejin.im/post/5a3137216fb9a0452b493caa) 

[从0开始弄一个面向OC数据库（三）](https://juejin.im/post/5a31ea18f265da43333e6a1c) 

[从0开始弄一个面向OC数据库（四）](https://juejin.im/post/5a3a158d6fb9a045211eda38) 

[从0开始弄一个面向OC数据库（五）](https://juejin.im/post/5a3e367f5188257c4d1b5e75) 
