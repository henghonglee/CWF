//
//  CWFHomeViewController.m
//  CWF
//
//  Created by HengHong on 17/7/12.
//
//

#import "CWFHomeViewController.h"

@interface CWFHomeViewController ()

@end

@implementation CWFHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *selectedImage0 = [UIImage imageNamed:@"HomeDB.png"];
    UIImage *unselectedImage0 = [UIImage imageNamed:@"HomeLB.png"];
    
    UIImage *selectedImage2 = [UIImage imageNamed:@"BuildingsDB.png"];
    UIImage *unselectedImage2 = [UIImage imageNamed:@"BuildingsLB.png"];
    
    UITabBar *tabBar = self.tabBarController.tabBar;
    UITabBarItem *item0 = [tabBar.items objectAtIndex:0];
    
    UITabBarItem *item2 = [tabBar.items objectAtIndex:2];
    
    
    [item0 setFinishedSelectedImage:selectedImage0 withFinishedUnselectedImage:unselectedImage0];
    
    [item2 setFinishedSelectedImage:selectedImage2 withFinishedUnselectedImage:unselectedImage2];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
