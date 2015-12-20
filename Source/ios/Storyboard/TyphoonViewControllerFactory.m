////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2015, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "TyphoonViewControllerFactory.h"

#import "TyphoonStoryboardDefinitionContext.h"
#import "TyphoonComponentFactory+Storyboard.h"
#import "TyphoonComponentFactory+TyphoonDefinitionRegisterer.h"
#import "UIViewController+TyphoonStoryboardIntegration.h"
#import "UIView+TyphoonDefinitionKey.h"

@interface TyphoonViewControllerFactory ()

@property (strong, nonatomic) TyphoonComponentFactory *factory;

@end

@implementation TyphoonViewControllerFactory

- (instancetype)initWithFactory:(TyphoonComponentFactory *)factory
{
    self = [super init];
    if (self) {
        _factory = factory;
    }
    return self;
}

- (UIViewController *)viewControllerWithStoryboardContext:(TyphoonStoryboardDefinitionContext *)context
{
    NSMutableDictionary *storyboardPool = [self.factory storyboardPool];
    
    UIStoryboard *storyboard = storyboardPool[context.storyboardName];
    if (!storyboard) {
        storyboard = [TyphoonStoryboard storyboardWithName:context.storyboardName
                                                   factory:self.factory
                                                    bundle:[NSBundle bundleForClass:[self class]]];
        @synchronized(self) {
            storyboardPool[context.storyboardName] = storyboard;
        }
    }
    
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:context.storyboardId];

    return viewController;
}

- (UIViewController *)viewControllerWithPrototype:(UIViewController *)prototype
{
    UIViewController *result = [self configureOrObtainFromPoolViewControllerForInstance:prototype];
    return result;
}

- (id)configureOrObtainFromPoolViewControllerForInstance:(UIViewController *)instance
{
    UIViewController *cachedInstance;
    
    cachedInstance = [self.factory scopeCachedViewControllerForInstance:instance typhoonKey:instance.typhoonKey];
    
    if (cachedInstance) {
        return cachedInstance;
    }
    
    [self injectPropertiesForViewController:instance];
    return instance;
}

- (void)injectPropertiesForViewController:(UIViewController *)viewController
{
    if (viewController.typhoonKey.length > 0) {
        [self.factory inject:viewController withSelector:NSSelectorFromString(viewController.typhoonKey)];
    }
    else {
        [self.factory inject:viewController];
    }
    
    for (UIViewController *controller in viewController.childViewControllers) {
        [self injectPropertiesForViewController:controller];
    }
    
    __weak __typeof (viewController) weakViewController = viewController;
    [viewController setViewDidLoadNotificationBlock:^{
        [self injectPropertiesInView:weakViewController.view];
    }];
}

- (void)injectPropertiesInView:(UIView *)view
{
    if (view.typhoonKey.length > 0) {
        [self.factory inject:view withSelector:NSSelectorFromString(view.typhoonKey)];
    }
    
    if ([view.subviews count] == 0) {
        return;
    }
    
    for (UIView *subview in view.subviews) {
        [self injectPropertiesInView:subview];
    }
}

@end