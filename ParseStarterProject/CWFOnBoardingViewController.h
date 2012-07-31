//
//  CWFOnBoardingViewController.h
//  CWF
//
//  Created by HengHong on 17/7/12.
//
//

#import <UIKit/UIKit.h>
#import "InstagramViewController.h"
#import "BaseViewController.h"

@interface CWFOnBoardingViewController : UIViewController <PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate,PF_FBRequestDelegate>
{
    int retrievedCount;
    int checkCount;
}
@property (nonatomic, retain) NSMutableArray* userCheckins;
@property (nonatomic, retain) NSMutableArray* checkinPFobjArray;
@property (nonatomic, retain) NSMutableArray* checkin_fb_ids_Array;
@property (nonatomic, retain) NSString* currEndpointURL;
@end
