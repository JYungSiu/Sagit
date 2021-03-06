//
//  开源：https://github.com/cyq1162/Sagit
//  作者：陈裕强 create on 2017/12/12.
//  博客：(昵称：路过秋天） http://www.cnblogs.com/cyq1162/
//  起源：IT恋、IT连 创业App http://www.itlinks.cn
//  Copyright © 2017-2027年. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "STController.h"
#import "STView.h"
#import "STCategory.h"
#import <objc/runtime.h>
#import "STDefine.h"
#import "STDefineUI.h"
#import "STMsgBox.h"
#import "STHttp.h"
@implementation STController

//ios 13.6 弹新窗兼容(13.6不能用扩展属性。。)
- (UIModalPresentationStyle)modalPresentationStyle{
    return UIModalPresentationFullScreen;
}
-(instancetype)init
{
    self=[super init];
    //初始化全局设置，必须要在UI初始之前。
    [self onInit];
    return self;
}

//局部状态栏隐藏(t)
//- (BOOL)prefersStatusBarHidden{
//   return ![self needStatusBar];
//}
- (void)viewDidLoad
{
    //检测上一个Controller
    [super viewDidLoad];
    [self loadUI];
    [self loadData];
}
-(void)viewWillDisappear:(BOOL)animated
{
    //NSLog(@"viewWillDisappear...%@", [self class]);
    if(!self.needStatusBar)
    {
        [self needStatusBar:YES forThisView:NO];
        [self needNavBar:NO forThisView:NO];
    }
    [self beforeViewDisappear];
    [super viewWillDisappear:animated];
   
}
-(void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"viewWillAppear...%@", [self class]);
    if(!self.needStatusBar)
    {
        [self needStatusBar:NO forThisView:NO];
    }
    if(self.needNavBar)
    {
        [self needNavBar:YES forThisView:NO];
    }
    [self beforeViewAppear];
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated
{
    if(self.nextController)
    {
        [self reSetBarState:YES];
    }
    [super viewDidAppear:animated];
}

//内部私有方法
-(void)loadUI{
    //获取当前的类名
    NSString* className= NSStringFromClass([self class]);
    NSString* viewClassName=[className replace:@"Controller" with:@"View"];
    Class viewClass=NSClassFromString(viewClassName);
    if(viewClass!=nil)//view
    {
        self.view=self.stView=[[viewClass alloc] initWithController:self];
        //[self.stView loadUI];
    }
    else
    {   //这一步，在ViewController中的loadView做了处理，默认self.view就是STView
        self.view=self.stView=[[STView alloc] initWithController:self];//将view换成STView
        //self.stView=self.view;
    }
    [self initUI];
}
//内部私有方法
-(void)loadData
{
    [self initData];
}
#pragma mark 通用的三个事件方法：onInit、initUI、initData(还有一个位于基类的：reloadData)
//在UI加载之前处理的
-(void)onInit{}
//加载UI时处理的
-(void)initUI
{
    [self.stView loadUI];
}
//加载UI后处理的
-(void)initData
{
    [self.stView initData];
}
-(void)beforeViewAppear{}
-(void)beforeViewDisappear{}

-(NSMapTable*)UIList
{
    return self.stView.UIList;
}
-(STMsgBox *)msgBox
{
    if(_msgBox==nil)
    {
        _msgBox=[STMsgBox new];
    }
    return _msgBox;
}
-(STHttp *)http
{
    if(_http==nil)
    {
        _http=[[STHttp alloc]init:self.msgBox];//不用单例，延时加载
    }
    return _http;
}
-(BOOL)isMatch:(NSString*)tipMsg value:(NSString*)value
{
    return [self isMatch:tipMsg value:value regex:nil];
}
-(BOOL)isMatch:(NSString*)tipMsg name:(NSString*)name
{
    return [self isMatch:tipMsg name:name regex:nil];
}
-(BOOL)isMatch:(NSString*)tipMsg name:(NSString*)name regex:(NSString*)pattern
{
    return [self isMatch:tipMsg value:[self stValue:name] regex:pattern];
}
-(BOOL)isMatch:(NSString*)tipMsg value:(NSString*)value regex:(NSString*)pattern
{
    if([NSString isNilOrEmpty:tipMsg]){return NO;}
    
    NSArray<NSString*> *items=[tipMsg split:@","];
    NSString *tip=items.firstObject;
    if([NSString isNilOrEmpty:value])
    {
        [self.msgBox prompt:[tip append:@"不能为空!"]];
        return NO;
    }
    else if(pattern!=nil && ![pattern isEqualToString:@""])
    {
        NSPredicate *match = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        if(match)
        {
            if(![match evaluateWithObject:value])
            {
                if(items.count==1)
                {
                    [self.msgBox prompt:[tip append:@"格式错误!"]];
                }
                else
                {
                    [self.msgBox prompt:[tipMsg replace:[tip append:@","] with:tip]];
                }
                return NO;
            }
        }
        match=nil;
    }
    return YES;
}
-(BOOL)isMatch:(NSString*)tipMsg isMatch:(BOOL)result
{
    if(!result)
    {
        [self.msgBox prompt:tipMsg];
    }
    return result;
}
-(void)stValue:(NSString*)name value:(NSString *)value
{
    UIView *ui=[self.UIList get:name];
    if(ui!=nil)
    {
        [ui stValue:value];
    }
}
//get set ui view....
-(NSString*)stValue:(NSString*)name
{
    UIView *ui=[self.UIList get:name];
    if(ui!=nil)
    {
        return ui.stValue;
    }
    return nil;
}
-(void)setToAll:(id)data{[self.stView setToAll:data];}
-(NSMutableDictionary*)formData{return [self.stView formData:nil];}
//!获取表单数据:superView 可以指定一个子UI。
-(NSMutableDictionary*)formData:(id)superView{return [self.stView formData:superView];}

-(void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    if([self key:@"dispose"]!=nil)
    {
        [self dispose];
    }
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if([self key:@"dispose"]!=nil)
    {
        [self dispose];
    }
    [super dismissViewControllerAnimated:flag completion:completion];
}


#pragma mark - UITableView 协议实现

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSString *num=[tableView key:@"sectionCount"];
    if(num!=nil)
    {
        return [num integerValue];
    }
    return 1;
}

// 返回行数
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count;
    NSArray<NSString*> *numb=[tableView key:@"rowCountInSections"];
    if(numb!=nil)
    {
        count= [numb[section] integerValue];
    }
    else
    {
        count=tableView.source.count;
    }
    tableView.separatorStyle=count>0?UITableViewCellSeparatorStyleSingleLine:UITableViewCellSeparatorStyleNone;
    return count;
}

// 设置cell
- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    UITableViewCell *cell=[UITableViewCell reuseCell:tableView index:indexPath];
    if(!tableView.reuseCell && cell.contentView.subviews.count>0){return cell;}
    if(tableView.addCell)
    {
        NSInteger row=indexPath.row;
        if(indexPath.section>0)
        {
            for (NSInteger i=0; i<indexPath.section; i++) {
                row+=[tableView numberOfRowsInSection:i];
            }
        }
        if(tableView.source.count>row)
        {
            cell.source=tableView.source[row];
            if([cell.source isKindOfClass:[NSDictionary class]])
            {
                [cell firstValue:((NSDictionary*)cell.source).firstObject];
            }
        }
        tableView.addCell(cell,indexPath);
        [cell stSizeToFit];//调整高度
    }
    NSMutableDictionary *dic=tableView.heightForCells;
    NSMutableArray *rows=dic[@(indexPath.section)];
    if(!rows)
    {
        rows=[NSMutableArray new];
        [dic set:@(indexPath.section) value:rows];
    }
    NSNumber *height=@(cell.frame.size.height);
    if(indexPath.row==rows.count)
    {
        [rows addObject:height];
    }
    else if(indexPath.row<rows.count)
    {
        rows[indexPath.row]=height;
    }
    else //处理乱序飞入
    {
        [dic setObject:height forKey:indexPath];
    }
    
    return cell;
}
//tableview 加载完成可以调用的方法--因为tableview的cell高度不定，所以在加载完成以后重新计算高度
-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row)
    {
        //cell.separatorInset = UIEdgeInsetsMake(0, STScreeWidthPt , 0, 0);//去掉最后一条线的
        if(tableView.autoHeight)
        {
            NSInteger relateBottomPx=0;
            //检测是否有向下的约束
            STLayoutTracer *tracer= tableView.LayoutTracer[@"relate"];
            if(tracer && tracer.hasRelateBottom)
            {
                relateBottomPx=tracer.relateBottomPx;
            }
            //检测是否高度超过屏
            NSInteger passValue=tableView.frame.origin.y+tableView.contentSize.height-tableView.superview.frame.size.height+relateBottomPx*Ypt;
            if(passValue>0)
            {
                tableView.scrollEnabled=YES;
                [tableView height:(tableView.contentSize.height-passValue-1)*Ypx];
            }
            else
            {
                [tableView height:(tableView.contentSize.height-1)*Ypx];//减1是去掉最后的线。
            }
        }
        if(tableView.afterReload)
        {
            //兼容IOS系统10.3.1(闪退的情况，所以延时0.05秒处理）
            //闪退的情况发现生在OS 10.3.1(在此事件中对TextView赋值,同时该TextView自适应高度又引发TableView BeginUpdate/EndUpdate事件时，系统崩溃
            //报错内容为系统的索引超出范围。
            [Sagit delayExecute:0.05 onMainThread:YES block:^{
                 tableView.afterReload(tableView);
            }];
        }
    }
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    NSMutableArray *rows=[tableView.heightForCells get:@(indexPath.section)];
    if(rows && rows.count>indexPath.row)
    {
        return [(NSNumber*)rows[indexPath.row] integerValue];
    }
    NSNumber *value=[tableView.heightForCells get:indexPath];//乱序飞入的情况
    if(value){return [value integerValue];}
    return 88*Ypt;
}
//这个方法存在时：estimatedHeightForRowAtIndexPath=>cellForRowAtIndexPath=>heightForRowAtIndexPath
//这方法不存在时：heightForRowAtIndexPath=》cellForRowAtIndexPath 这样会死循环
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88*Ypt;
}
// 添加每组的组头
//- (UIView *)tableView:(nonnull UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    return nil;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 0.01f;
//    //return tableView.tableHeaderView.frame.size.height;
//}
//-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
//{
//    return 0.01f;
//}
// 返回每组的组尾
//- (UIView *)tableView:(nonnull UITableView *)tableView viewForFooterInSection:(NSInteger)section{
//    return nil;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return tableView.tableFooterView.frame.size.height;
//}
//-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
//{
//    return 0.01f;
//}
// 选中某行cell时会调用
//- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
//    // NSLog(@"选中didSelectRowAtIndexPath row = %ld", indexPath.row);
//}
////
////// 取消选中某行cell会调用 (当我选中第0行的时候，如果现在要改为选中第1行 - 》会先取消选中第0行，然后调用选中第1行的操作)
//- (void)tableView:(nonnull UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
//
//    // NSLog(@"取消选中 didDeselectRowAtIndexPath row = %ld ", indexPath.row);
//}
#pragma mark UITableView 编辑删除
//先要设Cell可编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    if(cell!=nil)
    {
        return cell.allowDelete;
    }
    return tableView.allowDelete;
}
//定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}
//设置进入编辑状态时，Cell不会缩进，好像没生效。
- (BOOL)tableView: (UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
//点击删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    if(editingStyle==UITableViewCellEditingStyleDelete && tableView.delCell)
    {
        //STWeakObj(cell);//
        if(tableView.delCell(cell, indexPath))
        {
            [tableView afterDelCell:indexPath];
        }
    }
}

#pragma mark - UICollectionView 协议实现

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return collectionView.source.count;
}
//!控制方块的大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell=[collectionView cellForItemAtIndexPath:indexPath];
    if(cell!=nil)
    {
        return cell.frame.size;
    }
    return  CGSizeMake(100, 100);
}
///* 设置方块视图和边界的上下左右间距 */
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
//                        layout:(UICollectionViewLayout*)collectionViewLayout
//        insetForSectionAtIndex:(NSInteger)section;
//{
//    collectionView.collectionViewLayout;
//    UICollectionViewCell *cell=[collectionView cellForItemAtIndexPath:indexPath];
//    if(cell!=nil)
//    {
//        return cell.frame.size;
//    }
//    return  UIEdgeInsetsMake(10, 10, 10, 10);
//}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell=[UICollectionViewCell reuseCell:collectionView index:indexPath];
    if(collectionView.addCell)
    {
        if(collectionView.source.count>indexPath.row)
        {
            cell.source=collectionView.source[indexPath.row];
            [cell firstValue:cell.source.firstObject];
        }
        //默认设置
        collectionView.addCell(cell,indexPath);
    }
    return cell;
}
-(void)dealloc
{
    _http=nil;
    if(_msgBox)
    {
        [_msgBox hideLoading];//切换面页都将隐藏掉。
        _msgBox=nil;
    }
    _stView=nil;
    NSLog(@"STController relase -> %@", [self class]);
}
@end
