//
//  UIScrollView+VGParallaxHeader.m
//
//  Created by Marek Serafin on 2014-09-18.
//  Copyright (c) 2013 VG. All rights reserved.
//

#import "UIScrollView+VGParallaxHeader.h"

#import <objc/runtime.h>
#import <PureLayout/PureLayout.h>

static char UIScrollViewVGParallaxHeader;

#pragma mark - VGParallaxHeader (Interface)
@interface VGParallaxHeader ()

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                       contentView:(UIView *)view
                            height:(CGFloat)height;

@property (nonatomic, assign, readwrite, getter=isInsideTableView) BOOL insideTableView;

@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, strong, readwrite) UIView *contentView;

@property (nonatomic, weak, readwrite) UIScrollView *scrollView;

@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalHeight;

@property (nonatomic, strong, readwrite) NSLayoutConstraint *insetAwarePositionConstraint;
@property (nonatomic, strong, readwrite) NSLayoutConstraint *insetAwareSizeConstraint;

@end

#pragma mark - UIScrollView (Implementation)
@implementation UIScrollView (VGParallaxHeader)

- (void)setParallaxHeaderView:(UIView *)view
                       height:(CGFloat)height
{
    // New VGParallaxHeader
    self.parallaxHeader = [[VGParallaxHeader alloc] initWithScrollView:self
                                                           contentView:view
                                                                height:height];
    // Calling this to position everything right
    [self shouldPositionParallaxHeader];
    
    // If UIScrollView adjust inset
    if (!self.parallaxHeader.isInsideTableView) {
        UIEdgeInsets selfContentInset = self.contentInset;
        selfContentInset.top += height;
        
        self.contentInset = selfContentInset;
        self.contentOffset = CGPointMake(0, -selfContentInset.top);
    }
}

- (void)shouldPositionParallaxHeader
{
    if(self.parallaxHeader.isInsideTableView) {
        [self positionTableViewParallaxHeader];
    }
    else {
        [self positionScrollViewParallaxHeader];
    }
}

- (void)positionTableViewParallaxHeader
{
    if (self.contentOffset.y < self.parallaxHeader.originalHeight - 6) {
        
        //  Add contentOffsetY to height
        CGFloat grow = self.contentOffset.y * -1 + self.parallaxHeader.originalHeight;
        
        //  We can move height to if here because its uitableview
        CGFloat height = self.parallaxHeader.originalHeight;
        CGFloat y = 0;
        
        if (self.contentOffset.y < 0) {
            height = grow;
            y = self.contentOffset.y;
            self.scrollIndicatorInsets = UIEdgeInsetsMake(grow, 0, 0, 0);
        }
        
        //  Apply to frame
        self.parallaxHeader.containerView.frame = CGRectMake(0, y, CGRectGetWidth(self.frame), height);
    }
    else
    {
        // sticky
        self.parallaxHeader.containerView.frame = CGRectMake(0, self.contentOffset.y - self.parallaxHeader.originalHeight + 6, CGRectGetWidth(self.frame), self.parallaxHeader.originalHeight);
    }
}

- (void)positionScrollViewParallaxHeader
{
    CGFloat height = self.contentOffset.y * -1;
    
    if (self.contentOffset.y < 0) {
        // This is where the magic is happening
        self.parallaxHeader.frame = CGRectMake(0, self.contentOffset.y, CGRectGetWidth(self.frame), height);
    }
}

- (void)setParallaxHeader:(VGParallaxHeader *)parallaxHeader
{
    // Remove All Subviews
    if([self.subviews count] > 0) {
        [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([obj isMemberOfClass:[VGParallaxHeader class]]) {
                [obj removeFromSuperview];
            }
        }];
    }
    
    parallaxHeader.insideTableView = [self isKindOfClass:[UITableView class]];
    
    // Add Parallax Header
    if(parallaxHeader.isInsideTableView) {
        [(UITableView*)self setTableHeaderView:parallaxHeader];
        [parallaxHeader setNeedsLayout];
    }
    else {
        [self addSubview:parallaxHeader];
    }
    
    // Set Associated Object
    objc_setAssociatedObject(self, &UIScrollViewVGParallaxHeader, parallaxHeader, OBJC_ASSOCIATION_ASSIGN);
}

- (VGParallaxHeader *)parallaxHeader
{
    return objc_getAssociatedObject(self, &UIScrollViewVGParallaxHeader);
}

@end

#pragma mark - VGParallaxHeader (Implementation)
@implementation VGParallaxHeader

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                       contentView:(UIView *)view
                            height:(CGFloat)height
{
    self = [super initWithFrame:CGRectMake(0, 0, CGRectGetWidth(scrollView.bounds), height)];
    if (!self) {
        return nil;
    }
    
    self.scrollView = scrollView;
    
    self.originalHeight = height;
    self.originalTopInset = scrollView.contentInset.top;
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
//    self.containerView.clipsToBounds = YES;
    
    if (!self.isInsideTableView) {
        self.containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    
    [self addSubview:self.containerView];
    
    self.contentView = view;
    
    return self;
}

- (void)setContentView:(UIView *)contentView
{
    if(_contentView != nil) {
        [_contentView removeFromSuperview];
    }
    
    _contentView = contentView;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.containerView addSubview:_contentView];

    // Constraints
    [self addContentViewModeFillConstraints];
}

- (void)adjustHeightTo:(CGFloat)height animate:(BOOL)animate delay:(CGFloat)delay
{
    self.originalHeight = height;
    
    [UIView animateWithDuration:animate ? 0.35 : 0 delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:0.45 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        [self.scrollView positionTableViewParallaxHeader];
        
    } completion:nil];
}

- (void)setShadowPath
{
    CGRect frame = self.containerView.frame;
    frame.size.height = self.originalHeight;
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:frame].CGPath;
}

- (void)addContentViewModeFillConstraints
{
    [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeft
                                       withInset:0];
    [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeRight
                                       withInset:0];
    
    self.insetAwarePositionConstraint = [self.contentView autoAlignAxis:ALAxisHorizontal
                                                       toSameAxisOfView:self.containerView
                                                             withOffset:self.originalTopInset/2];
    
    self.insetAwareSizeConstraint = [self.contentView autoMatchDimension:ALDimensionHeight
                                                             toDimension:ALDimensionHeight
                                                                  ofView:self.containerView
                                                              withOffset:-self.originalTopInset];
    self.insetAwareSizeConstraint.priority = UILayoutPriorityDefaultHigh;
}

- (void)tintColorDidChange
{
    self.contentView.backgroundColor = self.tintColor;
}

@end
