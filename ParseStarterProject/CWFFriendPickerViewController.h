//
//  CWFFriendPickerViewController.h
//  CWF
//
//  Created by HengHong on 22/7/12.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
@protocol FPDelegate;
@interface CWFFriendPickerViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,PF_FBRequestDelegate,UITextFieldDelegate>

@property (nonatomic, retain) PF_FBRequest *myRequest;
@property (retain, nonatomic) id<FPDelegate> delegate;
@property (retain, nonatomic) NSMutableArray* FBfriendsArray;
@property (retain, nonatomic) NSMutableArray* friendsArray;
@property (retain, nonatomic) IBOutlet UITableView *friendTableView;
@property (retain, nonatomic) IBOutlet UITextField *pickerTextField;

@end
@protocol FPDelegate <NSObject>

-(void)FPDidReturnWithFriendUID:(NSString*)friendUid andName:(NSString*)friendName;

@end