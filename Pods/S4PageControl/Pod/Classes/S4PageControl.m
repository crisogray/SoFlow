//
//  S4PageControl.m
//  Seed4Me VPN
//
//  Created by Dmitry Abramov<dmitry.i.abramov@gmail.com> on 2/24/14.
//  Copyright (c) 2014 Dmitry Abramov. All rights reserved.
//

#import "S4PageControl.h"

@interface S4PageControl ()
{
@private

    NSUInteger _currentPage;
    NSUInteger _numberOfPages;
    UIColor* _currentPageIndicatorTintColor;
    UIColor* _pageIndicatorTintColor;
    CGSize _indicatorSize;
    CGFloat _indicatorSpace;
    S4IndicatorBlock _indicatorBlock;
}
@end

@implementation S4PageControl

@synthesize currentPage = _currentPage;
@synthesize numberOfPages = _numberOfPages;
@synthesize currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
@synthesize pageIndicatorTintColor = _pageIndicatorTintColor;
@synthesize indicatorSize = _indicatorSize;
@synthesize indicatorSpace = _indicatorSpace;
@synthesize indicatorBlock = _indicatorBlock;

- (id) init
{
    self = [super init];
    if (self) {
        self.currentPage = 0;
        self.numberOfPages = 0;
        self.currentPageIndicatorTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        self.pageIndicatorTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
        self.indicatorSize = CGSizeMake(8, 8);
        self.indicatorSpace = 8;
        self.opaque = NO;
        [self setIndicatorBlock:^(BOOL current, NSUInteger index, CGContextRef context, CGSize indicatorSize, UIColor* indicatorColor) {
            UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, indicatorSize.width, indicatorSize.height)];
            [indicatorColor setFill];
            [ovalPath fill];
        }];
    }
    return self;
}

- (void)setCurrentPage:(NSUInteger)currentPage
{
    if (currentPage == _currentPage)
        return;

    _currentPage = currentPage;
    [self setNeedsDisplay];
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages
{
    if (numberOfPages == _numberOfPages)
        return;

    _numberOfPages = numberOfPages;
    CGSize size = [self controlSize:_indicatorSize indicatorSpace:_indicatorSpace numberOfPages:_numberOfPages];
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    [self setNeedsDisplay];
}

- (void) setIndicatorSize:(CGSize)indicatorSize
{
    if (indicatorSize.width == _indicatorSize.width &&
        indicatorSize.height == _indicatorSize.height)
        return;

    _indicatorSize = indicatorSize;
    CGSize size = [self controlSize:_indicatorSize indicatorSpace:_indicatorSpace numberOfPages:_numberOfPages];
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    [self setNeedsDisplay];
}

- (void) setIndicatorSpace:(CGFloat)indicatorSpace
{
    if (indicatorSpace == _indicatorSpace)
        return;

    _indicatorSpace = indicatorSpace;
    CGSize size = [self controlSize:_indicatorSize indicatorSpace:_indicatorSpace numberOfPages:_numberOfPages];
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    [self setNeedsDisplay];
}

- (void)setIndicatorBlock:(S4IndicatorBlock)block
{
    _indicatorBlock = [block copy];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGSize size = [self controlSize:self.indicatorSize indicatorSpace:self.indicatorSpace numberOfPages:self.numberOfPages];
    CGFloat startDrawX = CGRectGetMidX(self.bounds) - size.width / 2;

    CGContextTranslateCTM(context, startDrawX, 0);
    self.indicatorBlock = ^(BOOL current, NSUInteger index, CGContextRef context, CGSize indicatorSize, UIColor* indicatorColor) {
        UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, indicatorSize.width, indicatorSize.height)];
        [indicatorColor setFill];
        [ovalPath fill];
    };
    for (int i = 0; i < self.numberOfPages; i++) {
        if (i > 0)
            CGContextTranslateCTM(context, self.indicatorSpace + self.indicatorSize.width, 0);

        CGContextSaveGState(context);
        if (self.currentPage == i) {
            self.indicatorBlock(TRUE, i, context, self.indicatorSize, self.currentPageIndicatorTintColor);
        } else {
            self.indicatorBlock(FALSE, i, context, self.indicatorSize, self.pageIndicatorTintColor);
        }
        CGContextRestoreGState(context);
    }
}

- (CGSize) controlSize:(CGSize) size indicatorSpace:(CGFloat) space numberOfPages:(NSInteger) pages
{
    return CGSizeMake(size.width * pages + space * (pages - 1), size.height);
}

@end
