//
//  CWFProfileViewController.h
//  CWF
//
//  Created by HengHong on 17/7/12.
//
//

#import <UIKit/UIKit.h>
#import "CWFFriendPickerViewController.h"
@interface CWFProfileViewController : UIViewController<FPDelegate,PF_FBRequestDelegate>
{
    int retrievedCount;
    int checkCount;
}
@property (nonatomic,retain) NSString* userForProfile;
@property (nonatomic, retain) NSMutableArray* userCheckins;
@property (nonatomic, retain) NSMutableArray* checkinPFobjArray;
@property (nonatomic, retain) NSString* currEndpointURL;




@property (retain, nonatomic) IBOutlet UILabel *nameLabel;

@property (retain, nonatomic) IBOutlet UILabel *totalCheckinLabel;
@property (retain, nonatomic) IBOutlet UILabel *uniqueFriendsLabel;
@property (retain, nonatomic) IBOutlet UILabel *nonUniqueFriendsLabel;
@property (retain, nonatomic) IBOutlet UILabel *scoreLabel;
@property (retain, nonatomic) IBOutlet UILabel *levelLabel;
@property (retain, nonatomic) IBOutlet UIProgressView *levelProgressBar;
@property (retain, nonatomic) IBOutlet UILabel *levelPercentLabel;

@end
