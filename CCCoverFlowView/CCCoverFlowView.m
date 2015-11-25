//
//  CCCoverFlowView.m
//  CCCoverFlowView
//
//  Created by 崔成 on 15/11/25.
//  Copyright © 2015年 崔成. All rights reserved.
//

#import "CCCoverFlowView.h"

@implementation CCCoverFlowView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    self.clipsToBounds = YES;
    
    _needReload = YES;
    _needRefresh = YES;
    _pageSize = self.bounds.size;
    _pageCount = 0;
    _currentPageIndex = 0;
    
    _minimumPageAlpha = 1.0f;
    _minimumPageScale = 1.0f;
    
    _reusableCells = [[NSMutableArray alloc] init];
    _inuseCells = [[NSMutableArray alloc] init];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.clipsToBounds = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    UIView *scrollViewSuperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    scrollViewSuperView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    scrollViewSuperView.backgroundColor = [UIColor whiteColor];
    [scrollViewSuperView addSubview:_scrollView];
    [self addSubview:scrollViewSuperView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_scrollView addGestureRecognizer:tap];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    if(_needReload)
    {
        [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if(_dataSource && [_dataSource respondsToSelector:@selector(numberOfPagesInFlowView:)])
        {
            _pageCount = [_dataSource numberOfPagesInFlowView:self];
        }
        if(_dataSource && [_dataSource respondsToSelector:@selector(numberOfPagesInFlowView:)])
        {
            _pageSize = [_dataSource sizeForPageInFlowView:self];
        }
        
        _visibleRange = NSMakeRange(0, 0);
        
        [_reusableCells removeAllObjects];
        [_inuseCells removeAllObjects];
        
        if(_pageCount == 0 && _defaultImageView)
        {
            self.defaultImageView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
            [_scrollView addSubview:self.defaultImageView];
        }
        
        NSInteger offset = 1;
        _scrollView.scrollEnabled = YES;
        if(_pageCount <= 1)
        {
            offset = 0;
            _scrollView.scrollEnabled = NO;
        }
        
        switch (_flowViewOrientation) {
            case FlowViewOrientationHorizontal:
            {
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width *3, _pageSize.height);
                
                CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = center;
                _scrollView.contentOffset = CGPointMake(_pageSize.width*offset, 0);
            }break;
            case FlowViewOrientationVertical:
            {
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width, _pageSize.height * 3);
                
                CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = center;
                _scrollView.contentOffset = CGPointMake(0, _pageSize.height *offset);
            }
            default:
                break;
        }
        [self loadRequiredItems];
        [self refreshVisibleCellAppearance];
    }
}
-(void)loadRequiredItems
{
    if(_pageCount <= 0) return;
    
    else if(_pageCount == 1)
    {
        UIView *cell = [_dataSource flowView:self cellForPageAtIndex:0];
        cell.tag = 0 + CCOffset;
        cell.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
        if(cell)
        {
            [_inuseCells addObject:cell];
            [_scrollView addSubview:cell];
        }
        return;
    }
    [self initVisibleCellAppearance];
    [self initReuseCell];
}
/**
 *  @author cuicheng, 15-11-25 13:11:36
 *
 *  创建cell  分别在  当前如果是第1个   则他左边的是 最后一个  中间的就是直接currentIndex 在判断 如果当前是最后一个  则他右边的 则应该是第一个
 *
 *  @since v6.2.0
 */
-(void)initVisibleCellAppearance
{
    _visibleRange = NSMakeRange(0, 3);
    
    NSInteger index = 0;
    
    index = (_currentPageIndex == 0)?_pageCount - 1:_currentPageIndex - 1;
    UIView *cell = [_dataSource flowView:self cellForPageAtIndex:index];
    cell.tag = index + CCOffset;
    cell.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
    if(cell)
    {
        [_inuseCells addObject:cell];
        [_scrollView addSubview:cell];
    }
    
    index = _currentPageIndex;
    UIView *cell1 = [_dataSource flowView:self cellForPageAtIndex:index];
    cell1.tag = index + CCOffset;
    cell1.frame = CGRectMake(_pageSize.width, 0, _pageSize.width, _pageSize.height);
    if(cell1)
    {
        [_inuseCells addObject:cell1];
        [_scrollView addSubview:cell1];
    }
    
    index = (_currentPageIndex == _pageCount -1)?0:_currentPageIndex +1;
    UIView *cell2 = [_dataSource flowView:self cellForPageAtIndex:index];
    cell2.tag = index + CCOffset;
    cell2.frame = CGRectMake(_pageSize.width * 2, 0, _pageSize.width, _pageSize.height);
    if(cell2)
    {
        [_inuseCells addObject:cell2];
        [_scrollView addSubview:cell2];
    }
}

-(void)initReuseCell
{
    if(_pageCount == 2)
    {
        for (int i = 0;i<2; i++)
        {
            NSInteger index = (_currentPageIndex == 0)?1:0;
            UIView *cell = [_dataSource flowView:self cellForPageAtIndex:index];
            cell.tag = index + CCOffset;
            cell.frame = CGRectMake(_pageSize.width*2*i, 0, _pageSize.width, _pageSize.height);
            if(cell)
                [_reusableCells addObject:cell];
        }
    }
    else if(_pageCount >2)
    {
        /**
         *  @author cuicheng, 15-11-25 14:11:44
         *
         *  cell1是最左边会被复用的也就是最后才会被复用的，cell2是马上即将被复用.
         *
         *  @since v6.2.0
         */
        //0时  0的左边为pageCount -1  在左边也就是复用的cell 为_pageCount -2;  下面同理
        NSInteger i = 0;
        if(_currentPageIndex == 0)              i = _pageCount -2;
        else if (_currentPageIndex - 1 == 0)    i = _pageCount - 1;
        else                                    i = _currentPageIndex -2;
        
        UIView *cell1 = [_dataSource flowView:self cellForPageAtIndex:i];
        cell1.tag = i + CCOffset;
        cell1.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
        if(cell1)
            [_reusableCells insertObject:cell1 atIndex:0];
        //如果当前是最后一个   则他下一个  是0   在下一个 就是马上要被复用的   是1  下面同理
        NSInteger index = 0;
        if(_currentPageIndex == _pageCount - 1)          index = 1;
        else if(_currentPageIndex + 1 == _pageCount - 1) index = 0;
        else                                             index = _currentPageIndex + 2;
        
        UIView *cell2 = [_dataSource flowView:self cellForPageAtIndex:index];
        cell2.tag = index + CCOffset;
        cell2.frame = CGRectMake(_pageSize.width *2, 0, _pageSize.width, _pageSize.height);
        if(cell2)
           [_reusableCells addObject:cell2];
    }
}

-(void)queueReusableCell:(UIView *)cell
{
    if(cell)
    {
        [_reusableCells addObject:cell];
    }
}

-(UIView *)dequeueReusableCell
{
    return nil;
}

-(void)reloadData
{
    _needReload = YES;
    [self setNeedsDisplay];
}

-(void)refreshVisibleCellAppearance
{
    if(_minimumPageAlpha == 1.0f && _minimumPageScale == 1.0f)
        return;
    switch (_flowViewOrientation) {
        case FlowViewOrientationHorizontal:
        {
            CGFloat offset = _scrollView.contentOffset.x;
            
            for(int i = (int) _visibleRange.location;i<_visibleRange.length+_visibleRange.location;i++)
            {
                UIView *cell = [_inuseCells objectAtIndex:i];
                CGFloat origin = cell.frame.origin.x;
                CGFloat delta = fabs(origin - offset);
                
                CGRect originCellFrame = CGRectMake(_pageSize.width * i, 0, _pageSize.width, _pageSize.height);
                
                if(delta < _pageSize.width)
                {
                    cell.alpha = 1 - (delta / _pageSize.width) *(1 - _minimumPageAlpha);
                    CGFloat inset = (_pageSize.width *(1 - _minimumPageScale)) *(delta / _pageSize.width)/2.0f;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }
                else
                {
                    cell.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.width * (1 - _minimumPageScale)/2.0f;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }
            }
        }
            break;
        case FlowViewOrientationVertical:
        {
            CGFloat offset = _scrollView.contentOffset.y;
            
            for (int i = (int) _visibleRange.location; i < _visibleRange.location + _visibleRange.length; i++) {
                UIView *cell = [_inuseCells objectAtIndex:i];
                CGFloat origin = cell.frame.origin.y;
                CGFloat delta = fabs(origin - offset);
                
                CGRect originCellFrame = CGRectMake(0, _pageSize.height * i, _pageSize.width, _pageSize.height);//如果没有缩小效果的情况下的本该的Frame
                
                if (delta < _pageSize.height) {
                    cell.alpha = 1 - (delta / _pageSize.height) * (1 - _minimumPageAlpha);
                    
                    CGFloat inset = (_pageSize.height * (1 - _minimumPageScale)) * (delta / _pageSize.height)/2.0;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                } else {
                    cell.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.height * (1 - _minimumPageScale) / 2.0 ;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }
            }
        }break;
        default:
            break;
    }
}
- (UIView *)cellForItemAtCurrentIndex:(NSInteger)currentIndex
{
    UIView  *cell = nil;
    if ([_inuseCells count] == 1) {
        cell = [_inuseCells objectAtIndex:0];
    }else if ([_inuseCells count]>1){
        cell = [_inuseCells objectAtIndex:1];
    }
    return cell;
}
-(void)reloadDataForScrollView:(PageDirection)direction
{
    if (direction == PageDirectionPrevious) {
        
        UIView  *oldItem = [_inuseCells objectAtIndex:0];
        [_inuseCells removeObjectIdenticalTo:oldItem];
        
        for (NSInteger  i=0; i<[_inuseCells count]; i++) {
            UIView  *v = [_inuseCells objectAtIndex:i];
            v.frame = CGRectMake(_pageSize.width*i, 0, _pageSize.width, _pageSize.height);
        }
        
        UIView *newItem = [_reusableCells lastObject];
        [_reusableCells removeObjectIdenticalTo:newItem];
        [_scrollView addSubview:newItem];
        [_inuseCells addObject:newItem];
        
        
        oldItem.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
        [_reusableCells insertObject:oldItem atIndex:0];
        [oldItem removeFromSuperview];
        
        
        UIView  *reuseCell = [_reusableCells lastObject];
        reuseCell.frame = CGRectMake(_pageSize.width*2, 0, _pageSize.width, _pageSize.height);
        [_delegate didReloadData:reuseCell cellForPageAtIndex:reuseCell.tag - CCOffset];
        
    }else if(direction == PageDirectionDown){
        
        UIView  *oldItem = [_inuseCells lastObject];
        [_inuseCells removeObjectIdenticalTo:oldItem];
        
        for (NSInteger  i=0; i<[_inuseCells count]; i++) {
            UIView  *v = [_inuseCells objectAtIndex:i];
            v.frame = CGRectMake(_pageSize.width*(i+1), 0, _pageSize.width, _pageSize.height);
        }
        
        UIView *newItem = [_reusableCells objectAtIndex:0];
        [_reusableCells removeObjectIdenticalTo:newItem];
        [_scrollView addSubview:newItem];
        [_inuseCells insertObject:newItem atIndex:0];
        
        
        oldItem.frame = CGRectMake(_pageSize.width*2, 0, _pageSize.width, _pageSize.height);
        [_reusableCells addObject:oldItem];
        [oldItem removeFromSuperview];
        
        UIView  *reuseCell = [_reusableCells objectAtIndex:0];
        reuseCell.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
        [_delegate didReloadData:reuseCell cellForPageAtIndex:reuseCell.tag - CCOffset];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(_pageCount <= 1)
    {
        return;
    }
    
    [self refreshVisibleCellAppearance];
}

- (NSInteger)validPageValue:(NSInteger)value
{
    if(value < 0) value = _pageCount-1;                   // value＝1为第一张，value = 0为前面一张
    if(value >= _pageCount) value = 0;
    
    return value;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int x = scrollView.contentOffset.x;
    int y = scrollView.contentOffset.y;
    
    if(_flowViewOrientation == FlowViewOrientationHorizontal)
    {
        if(x >= (2*_scrollView.bounds.size.width))
        {
            _currentPageIndex = [self validPageValue:_currentPageIndex +1];
            [self reloadDataForScrollView:PageDirectionPrevious];
        }
        else if(x <= 0)
        {
            _currentPageIndex = [self validPageValue:_currentPageIndex -1];
            [self reloadDataForScrollView:PageDirectionDown];
        }
    }
    else if (_flowViewOrientation == FlowViewOrientationVertical)
    {
        if(y >= 2*(_scrollView.bounds.size.height))
        {
            _currentPageIndex = [self validPageValue:_currentPageIndex + 1];
            [self reloadDataForScrollView:PageDirectionPrevious];
        }
        else if(y <= 0)
        {
            _currentPageIndex = [self validPageValue:_currentPageIndex - 1];
            [self reloadDataForScrollView:PageDirectionDown];
        }
    }
    
    if ([_delegate respondsToSelector:@selector(didScrollToPage:inFlowView:)]) {
        [_delegate didScrollToPage:_currentPageIndex inFlowView:self];
    }
    
    if (_flowViewOrientation == FlowViewOrientationHorizontal) {
        [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width, 0) animated:NO];
    }
    if (_flowViewOrientation == FlowViewOrientationVertical) {
        [_scrollView setContentOffset:CGPointMake(0, _scrollView.bounds.size.height) animated:NO];
    }
}
- (void)scrollToNextPage
{
    UIView *newItem = [_reusableCells lastObject];
    newItem.frame = CGRectMake(_pageSize.width*3, 0, _pageSize.width, _pageSize.height);
    [_reusableCells removeObjectIdenticalTo:newItem];
    [_scrollView addSubview:newItem];
    [_inuseCells addObject:newItem];
    
    UIView  *oldItem = [_inuseCells objectAtIndex:0];
    
    _currentPageIndex = [self validPageValue:_currentPageIndex+1];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         for (NSInteger  i=0; i<[_inuseCells count]; i++) {
                             UIView  *v = [_inuseCells objectAtIndex:i];
                             v.frame = CGRectMake(_pageSize.width*(i-1), 0, _pageSize.width, _pageSize.height);
                         }
                         [_inuseCells removeObjectAtIndex:0];
                         [self refreshVisibleCellAppearance];
                         
                     } completion:^(BOOL finished) {

                         oldItem.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                         [_reusableCells insertObject:oldItem atIndex:0];
                         [oldItem removeFromSuperview];
                         
                         UIView  *reuseCell = [_reusableCells lastObject];
                         reuseCell.frame = CGRectMake(_pageSize.width*2, 0, _pageSize.width, _pageSize.height);
                         [_delegate didReloadData:reuseCell cellForPageAtIndex:reuseCell.tag - CCOffset];
                         
                     }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGRect  frame = CGRectMake(_scrollView.center.x-_pageSize.width/2,
                               _scrollView.center.y-_pageSize.height/2,
                               _pageSize.width, _pageSize.height);
    CGPoint  point = [gestureRecognizer locationInView:_scrollView];
    if(CGRectContainsPoint(frame, point)){
        return YES;
    }
    return NO;
}


- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer{
    if ([_delegate respondsToSelector:@selector(didSelectItemAtIndex:inFlowView:)]) {
        [_delegate didSelectItemAtIndex:_currentPageIndex inFlowView:self];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
