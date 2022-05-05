//
//  S4PageControl.h
//  Seed4Me VPN
//
//  Created by Dmitry Abramov<dmitry.i.abramov@gmail.com> on 2/24/14.
//  Copyright (c) 2014 Dmitry Abramov. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * S4IndicatorBlock is the definition of callback method to draw indicator shape.
 * @param current - flag which shows whether the indicator represent the current page
 * @param index - index of the current indicator
 * @param context - drawing context to draw the shape
 * @param indicatorSize - the current indicator size
 * @param indicatorColor - the current indicator color
 */
typedef void(^S4IndicatorBlock)(BOOL current, NSUInteger index, CGContextRef context, CGSize indicatorSize, UIColor* indicatorColor);

/**
 * S4PageControl class has functionality similar to UIPageControl.
 * This control is more powerful that standard one as it gives
 * flexibility for developers. It allows to change not only color,
 * but also size and shape of indicators.
 *
 * Additional properties:
 * - @see indicatorSize
 * - @see indicatorSpace
 * - @see indicatorBlock
 *
 *  S4PageControl* pageControl = [S4PageControl new];
 *  pageControl.center = CGPointMake(self.view.center.x, 20);
 *  pageControl.numberOfPages = 5;
 *  pageControl.currentPage = 0;
 *  [pageControl setIndicatorBlock:^(BOOL current, NSUInteger index, CGContextRef context, CGSize indicatorSize, UIColor* indicatorColor) {
 *      UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, indicatorSize.width, indicatorSize.height)];
 *      [indicatorColor setFill];
 *      [ovalPath fill];
 *  }];
 *
 */
@interface S4PageControl : UIControl

/**
 * The number of pages, which are shown on the control.
 * The default value is 0.
 */
@property(nonatomic, assign) NSUInteger numberOfPages;

/**
 * The current page of the control.
 * The default value is 0.
 */
@property(nonatomic, assign) NSUInteger currentPage;

/**
 * The current page indicator color.
 * The default value is  white - RGBA(1.0, 1.0, 1.0, 1.0).
 */
@property(nonatomic, strong) UIColor* currentPageIndicatorTintColor;

/**
 * The page indicator color of pages, which are not selected.
 * The default value is RGBA(1.0, 1.0, 1.0, 0.6).
 */
@property(nonatomic, strong) UIColor* pageIndicatorTintColor;

/**
 * The size of indicator element.
 * The default value is (8,8).
 */
@property(nonatomic, assign) CGSize indicatorSize;

/**
 * The size of space between indicators.
 * The default value is 8.
 */
@property(nonatomic, assign) CGFloat indicatorSpace;

/**
 * The block of code which draws the indicator shape.
 * The default block draws a circle.
 */
@property(nonatomic, copy) S4IndicatorBlock indicatorBlock;

@end
