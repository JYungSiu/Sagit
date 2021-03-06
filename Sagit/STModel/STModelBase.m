//
//  开源：https://github.com/cyq1162/Sagit
//  作者：陈裕强 create on 2017/12/12.
//  博客：(昵称：路过秋天） http://www.cnblogs.com/cyq1162/
//  起源：IT恋、IT连 创业App http://www.itlinks.cn
//  Copyright © 2017-2027年. All rights reserved.
//

#import "STModelBase.h"

@implementation STModelBase

-(BOOL)isIgnoreCase
{
    return YES;
}
-(BOOL)isIgnore:(NSString *)namel
{
    return NO;
}
-(id)init
{
    return self;
}
-(id)initWithObject:(id<NSObject>)msg
{
    return [self initWithDictionary:(NSDictionary*)msg];
}
-(id)initWithDictionary:(NSDictionary *)dic
{
    self=[self init];
    [NSDictionary dictionaryToEntity:dic to:self];
    return self;
}
-(NSDictionary *)toDictionary{
    NSDictionary *dic=[NSMutableDictionary initWithJsonOrEntity:self];
    return dic;
}
-(NSString *)toJson
{
   return [[self toDictionary] toJson];
}
+(NSArray<id>* )toArrayEntityFrom:(NSArray*)array
{
    if(array==nil || array.count==0)
    {
        return nil;
    }
    NSMutableArray *returnArray=[NSMutableArray new];
    //NSString *name=NSStringFromClass([self class]);
    for (int i=0; i<array.count; i++) {
        Class class=[self class];
        id obj=[[class alloc] init];
        [NSDictionary dictionaryToEntity:array[i] to:obj];
        [returnArray addObject:obj];
    }
    return returnArray;
    
}

@end
