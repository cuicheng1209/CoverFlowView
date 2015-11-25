//
//  CCCoverFlowView.h
//  CCCoverFlowView
//
//  Created by 崔成 on 15/11/25.
//  Copyright © 2015年 崔成. All rights reserved.
//
#define CCOffset   50
#import <UIKit/UIKit.h>

/**
 横纵
 */
typedef enum {
    FlowViewOrientationHorizontal = 0,
    FlowViewOrientationVertical
}FlowViewOrientation;

/**
 上一页，下一页
 */
typedef enum {
    PageDirectionPrevious = 0,
    PageDirectionDown
}PageDirection;

@protocol CCCoverFlowViewDelegate;
@protocol CCCoverFlowViewDataSource;

@interface CCCoverFlowView : UIView <UIScrollViewDelegate>
{
    UIScrollView            *_scrollView;
    BOOL                    _needReload;
    BOOL                    _needRefresh;
    CGSize                  _pageSize;
    NSInteger                  _pageCount;
    NSRange                 _visibleRange;
    NSMutableArray          *_reusableCells;
    NSMutableArray          *_inuseCells;
    CGFloat                 _minimumPageAlpha;
    CGFloat                 _minimumPageScale;
}
@property (nonatomic,weak) id <CCCoverFlowViewDataSource> dataSource;
@property (nonatomic,weak) id <CCCoverFlowViewDelegate> delegate;
@property (nonatomic,retain) UIImageView *defaultImageView;
@property (nonatomic,assign) FlowViewOrientation flowViewOrientation;
@property (nonatomic,assign,readonly) NSInteger currentPageIndex;
@property (nonatomic,assign) CGFloat minimumPageAlpha;
@property (nonatomic,assign) CGFloat minimumPageScale;
@property (nonatomic,retain) NSArray *data;
-(void)reloadData;
-(UIView *)dequeueReusableCell;
-(UIView *)cellForItemAtCurrentIndex:(NSInteger)index;
@end

@protocol CCCoverFlowViewDelegate <NSObject>

-(void)didReloadData:(UIView *)cell cellForPageAtIndex:(NSInteger)index;
@optional
-(void)didScrollToPage:(NSInteger)pageIndex inFlowView:(CCCoverFlowView *)flowView;
-(void)didSelectItemAtIndex:(NSInteger)index inFlowView:(CCCoverFlowView *)flowView;
@end

@protocol CCCoverFlowViewDataSource <NSObject>

-(NSInteger)numberOfPagesInFlowView:(CCCoverFlowView *)flowView;
-(CGSize)sizeForPageInFlowView:(CCCoverFlowView *)flowView;
-(UIView *)flowView:(CCCoverFlowView *)flowView cellForPageAtIndex:(NSInteger)index;
@end