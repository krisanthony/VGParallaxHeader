//
//  UIScrollView+VKParallaxHeader.m
//
//  Created by Marek Serafin on 2014-09-18.
//  Copyright (c) 2013 VG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VGParallaxHeader : UIView

- (void)adjustHeightTo:(CGFloat)height animate:(BOOL)animate delay:(CGFloat)delay;
- (void)applyShadow;
- (void)removeShadow;

@end

@interface UIScrollView (VGParallaxHeader)

@property (nonatomic, strong, readonly) VGParallaxHeader *parallaxHeader;

- (void)setParallaxHeaderView:(UIView *)view
                       height:(CGFloat)height;

- (void)positionParallaxHeader;

@end
