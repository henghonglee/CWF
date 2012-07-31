//
//  CWFProfileViewController.m
//  CWF
//
//  Created by HengHong on 17/7/12.
//
//

#import "CWFProfileViewController.h"
#import "CWFFriendPickerViewController.h"

@interface CWFProfileViewController ()

@end

@implementation CWFProfileViewController
@synthesize userCheckins,checkinPFobjArray,currEndpointURL;

@synthesize userForProfile;
@synthesize nameLabel;
@synthesize totalCheckinLabel;
@synthesize uniqueFriendsLabel;
@synthesize nonUniqueFriendsLabel;
@synthesize scoreLabel;
@synthesize levelLabel;
@synthesize levelProgressBar;
@synthesize levelPercentLabel;
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

    userCheckins = [[NSMutableArray alloc]init];
    checkinPFobjArray = [[NSMutableArray alloc]init];
    
    retrievedCount=0;
    checkCount=0;
    [self resetUser:nil];
    
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)refresh:(id)sender {
//    totalCheckinLabel.text = [ NSString stringWithFormat:@"%d",[[[PFUser currentUser] objectForKey:@"checkin_fb_ids"]count]];
    NSMutableArray* uniqueFriendsArray = [[NSMutableArray alloc]init];
    NSMutableArray* nonUniqueFriendsArray = [[NSMutableArray alloc]init];
    __block int totalScore=0;
    PFQuery *checkinQuery = [PFQuery queryWithClassName:@"CheckIn"];
    NSLog(@"checking query added userprofile =%@",userForProfile);
    
    [checkinQuery whereKey:@"tagged_users_ids" containsString:userForProfile];
    [checkinQuery setLimit:500];
    [checkinQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        totalCheckinLabel.text = [ NSString stringWithFormat:@"%d",[objects count]];
        for (PFObject* checkinObj in objects) {
            int scoreForCheckin = pow([[checkinObj objectForKey:@"tagged_users_ids"]count],2);
            totalScore = totalScore+scoreForCheckin;
            for (NSString* taggeduserid in [checkinObj objectForKey:@"tagged_users_ids"]) {
                if (![uniqueFriendsArray containsObject:taggeduserid]) {
                    [uniqueFriendsArray addObject:taggeduserid];
                }
                [nonUniqueFriendsArray addObject:taggeduserid];
            }
        }
        uniqueFriendsLabel.text = [NSString stringWithFormat:@"%d",[uniqueFriendsArray count]];
        nonUniqueFriendsLabel.text = [NSString stringWithFormat:@"%d",[nonUniqueFriendsArray count]];
        scoreLabel.text = [NSString stringWithFormat:@"%d",totalScore];
        int level = (int)((1+sqrt(totalScore/20 + 1))/2);
        float percentToNextLevel = (((1+sqrt(totalScore/20 + 1))/2) - level);
        levelProgressBar.progress = percentToNextLevel;
        levelPercentLabel.text = [NSString stringWithFormat:@"%d/%d points to Level %d (%d%%)",totalScore,20*(((level+1)*2-1)*((level+1)*2-1)),level+1,(int)(percentToNextLevel*100)];
        levelLabel.text = [NSString stringWithFormat:@"%d", level];
        [uniqueFriendsArray release];
        [nonUniqueFriendsArray release];
    }];
    
}
- (IBAction)checkFriendsScore:(id)sender {
    //TODO: bring up friend picker, set self as friend picker delegate
    CWFFriendPickerViewController* FriendPickerVC = [[CWFFriendPickerViewController alloc]initWithNibName:@"CWFFriendPickerViewController" bundle:nil];
    FriendPickerVC.delegate = self;
    [self.navigationController pushViewController:FriendPickerVC animated:YES];
    [FriendPickerVC release];
    
}
-(void)FPDidReturnWithFriendUID:(NSString*)friendUid andName:(NSString *)friendName
{
    NSLog(@"friendid = %@",friendUid);
        nameLabel.text = [NSString stringWithFormat:@"%@",friendName];
       userForProfile = friendUid;
    [userForProfile retain];
    
    //reset values
    retrievedCount=0;
    checkCount=0;
    [userCheckins removeAllObjects];
    [checkinPFobjArray removeAllObjects];
    [self fbGraphCall:[NSString stringWithFormat:@"/%@/checkins?limit=20&fields=id,place,created_time,tags,from",friendUid]];
 
}
-(void)fbGraphCall:(NSString*)endpointURL
{
    currEndpointURL = endpointURL;
    NSLog(@"retrieving user checkins, accesstoken = %@",[[PFFacebookUtils facebook]accessToken]);
    NSMutableDictionary* reqParams = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"checkInRequest",@"type", nil];
    [[PFFacebookUtils facebook] requestWithGraphPath:endpointURL andParams:reqParams andDelegate:self];
    [reqParams release];
    
    
}
- (void)request:(PF_FBRequest *)request didLoad:(id)result {
   
    if ([[request.params objectForKey:@"type"] isEqualToString:@"checkInRequest"]) {
        NSLog(@"result = %@",result);
        if ([[result objectForKey:@"data"] isKindOfClass:[NSArray class]]&&[[result objectForKey:@"data"]count]>0 ) {
            
            for (id object in [result objectForKey:@"data"]) { //for every checkin
                retrievedCount++;
                
                NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'+0000'"];
                NSString* datestring = ((NSString*)[object objectForKey:@"created_time"]);
                NSDate * date = [dateFormatter dateFromString:datestring];
                [dateFormatter release];
                if (!datestring) {
                    date = ((NSDate*)[object objectForKey:@"created_time"]);
                }
                double unixTimestamp = [date timeIntervalSince1970];
                NSLog(@"created at %f",unixTimestamp);
                
                PFQuery* queryForCheckin = [PFQuery queryWithClassName:@"CheckIn"];
                
                //cant be the same checkin(ie. cant have same checkin id)
                [queryForCheckin whereKey:@"fb_id" equalTo:[object objectForKey:@"id"]];
                
                
                
                
                [queryForCheckin getFirstObjectInBackgroundWithBlock:^(PFObject *checkedin, NSError *error) {
                    
                    if (!checkedin) {
                        
                        //FIXME:potential bug as user first adds checkins to not be able to detect clashes
                        
                        PFQuery* checkValidity = [PFQuery queryWithClassName:@"CheckIn"];
                        PFGeoPoint* checkinGP = [PFGeoPoint geoPointWithLatitude:((double)[[[object objectForKey:@"location"] objectForKey:@"latitude"]doubleValue]) longitude:((double)[[[object objectForKey:@"location"] objectForKey:@"longitude"]doubleValue])];
                        
                        //TODO:checkin now set to THAT point , should be a box, find out how much is meters in lat/lon and add that to the geopoint
                        
                        [checkValidity whereKey:@"checkin_geopoint" nearGeoPoint:checkinGP withinKilometers:0.5];
                        
                        //checkin owner cant be the same
                        NSLog(@"owner cant be the same as %@",[[object objectForKey:@"from"] objectForKey:@"id"]);
                        [checkValidity whereKey:@"creator_id" equalTo:[[object objectForKey:@"from"] objectForKey:@"id"]];
                        
                        //check if theres any checkins nearby
                        //cant be too near in timing
                        // NSLog(@"timestamp cant be the less than as %@ and more than %@",[NSNumber numberWithDouble:unixTimestamp+10800],[NSNumber numberWithDouble:unixTimestamp-10800]);
                        [checkValidity whereKey:@"unixtimestamp" greaterThan:[NSNumber numberWithDouble:unixTimestamp-10800]];
                        [checkValidity whereKey:@"unixtimestamp" lessThan:[NSNumber numberWithDouble:unixTimestamp+10800]];
                        [checkValidity getFirstObjectInBackgroundWithBlock:^(PFObject *firstObj, NSError *error) {
                            if (!firstObj) {
                                NSLog(@"didnt find first obj..continue to save");
                                PFObject* checkin = [PFObject objectWithClassName:@"CheckIn"];
                                NSMutableArray* taggedFriendsIdArray = [[NSMutableArray alloc]init];
                                NSMutableArray* taggedFriendsNameArray = [[NSMutableArray alloc]init];
                                [checkin setObject:[object objectForKey:@"id"] forKey:@"fb_id"];
                                [checkin setObject:[[object objectForKey:@"place"] objectForKey:@"id"] forKey:@"place_id"];
                                [checkin setObject:[[object objectForKey:@"place"] objectForKey:@"name"] forKey:@"place_name"];
                                [checkin setObject:[NSNumber numberWithDouble:unixTimestamp] forKey:@"unixtimestamp"];
                                [checkin setObject:checkinGP forKey:@"checkin_geopoint"];
                                //2012-07-18T05:12:54+0000
                                
                                //Find the subcategories and add them to the check_in_categories array
                                
                                //                    [NSArray arrayWithObject:[[object objectForKey:@"place"] objectForKey:@"name"]
                                
                                [checkin setObject:[[object objectForKey:@"from"] objectForKey:@"name"] forKey:@"creator_name"];
                                [taggedFriendsNameArray addObject:[[object objectForKey:@"from"] objectForKey:@"name"]];
                                [checkin setObject:[[object objectForKey:@"from"] objectForKey:@"id"] forKey:@"creator_id"];
                                [taggedFriendsIdArray addObject:[[object objectForKey:@"from"] objectForKey:@"id"]];
                                
                                
                                for (id tag in [[object objectForKey:@"tags"]objectForKey:@"data"]) { //inside tag is data array of id and names
                                    [taggedFriendsIdArray addObject:[tag objectForKey:@"id"]];
                                    [taggedFriendsNameArray addObject:[tag objectForKey:@"name"]];
                                }
                                [checkin setObject:taggedFriendsIdArray forKey:@"tagged_users_ids"];
                                [checkin setObject:taggedFriendsNameArray forKey:@"tagged_users_names"];
                                [checkinPFobjArray addObject:checkin];
                                [userCheckins addObject:checkin];
                                NSLog(@"checkincount = %d, retrieved = %d",[userCheckins count],retrievedCount);
                                if ([userCheckins count]==retrievedCount) {
                                    
                                    
                                    for (PFObject* checkin in userCheckins) {
                                        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                       [NSString stringWithFormat:@"SELECT categories , pic_small,type,location FROM page WHERE page_id IN (SELECT page_id FROM checkin WHERE checkin_id=%@)",[checkin objectForKey:@"fb_id"]], @"query",@"categoryRequest",@"type",[checkin objectForKey:@"fb_id"],@"fb_id",nil];
                                        [[PFFacebookUtils facebook] requestWithMethodName:@"fql.query"
                                                                                andParams:params
                                                                            andHttpMethod:@"POST"
                                                                              andDelegate:self];
                                    }
                                    
                                    
                                }
                                
                            }else{
                                //duplicate checkin
                                NSLog(@"checkin at %@ doesnt fit rules",[firstObj objectForKey:@"place_name"]);
                                retrievedCount--;
                            }
                        }];
                        
                        
                    }else{
                        
                        //duplicate checkin
                        NSLog(@"duplicated checkin at %@",[checkedin objectForKey:@"place_name"]);
                        retrievedCount--;
                    }
                    
                }];
                
            }
            
            
            
            
            NSString* nextPageEndpointURL = [[[result objectForKey:@"paging"] objectForKey:@"next"] stringByReplacingOccurrencesOfString:@"https://graph.facebook.com/" withString:@""];
            
            
            [self performSelector:@selector(fbGraphCall:) withObject:nextPageEndpointURL];
            
            
            
            
            
        }else{
//            NSLog(@"wrapping up for part2");
//            for (PFObject* checkin in userCheckins) {
//                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                               [NSString stringWithFormat:@"SELECT categories , pic_small,type,location FROM page WHERE page_id IN (SELECT page_id FROM checkin WHERE checkin_id=%@)",[checkin objectForKey:@"fb_id"]], @"query",@"categoryRequest",@"type",[checkin objectForKey:@"fb_id"],@"fb_id",nil];
//                [[PFFacebookUtils facebook] requestWithMethodName:@"fql.query"
//                                                        andParams:params
//                                                    andHttpMethod:@"POST"
//                                                      andDelegate:self];
//            }
//                                [self refresh:nil];
        }
    }
    if ([[request.params objectForKey:@"type"] isEqualToString:@"categoryRequest"]) {

        for (PFObject* checkinpf in checkinPFobjArray) {
            
            if ([[checkinpf objectForKey:@"fb_id"]isEqualToString:[request.params objectForKey:@"fb_id"]]) {
                //Add subcategories,pic, to PFObject
                for(id catObj in [[((NSArray*)result) objectAtIndex:0] objectForKey:@"categories"]){
                    [checkinpf addUniqueObject:[catObj objectForKey:@"name"] forKey:@"categories"];
                }
                [checkinpf setObject:[[[((NSArray*)result) objectAtIndex:0]  objectForKey:@"location"] objectForKey:@"latitude"] forKey:@"latitude"];
                [checkinpf setObject:[[[((NSArray*)result) objectAtIndex:0]  objectForKey:@"location"] objectForKey:@"latitude"] forKey:@"latitude"];
                [checkinpf setObject:[[((NSArray*)result) objectAtIndex:0]  objectForKey:@"pic_small"] forKey:@"image_link"];
                
                
            }
            
        }
        
        checkCount++;
          NSLog(@"usercheckins = %d, checkcount = %d",[userCheckins count],checkCount);
        if (checkCount == [userCheckins count]) {
            [PFObject saveAllInBackground:userCheckins block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self refresh:nil];
                    NSLog(@"done saving all");
                }
            }];
        }
    }
    
}

- (IBAction)resetUser:(id)sender {
    userForProfile = [[PFUser currentUser]objectForKey:@"fb_id"];
    nameLabel.text = [[PFUser currentUser]objectForKey:@"full_name"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [totalCheckinLabel release];
    [uniqueFriendsLabel release];
    [nonUniqueFriendsLabel release];
    [scoreLabel release];
    [levelLabel release];
    [levelProgressBar release];
    [levelPercentLabel release];
    [userCheckins release];

    [checkinPFobjArray release];
    
    retrievedCount=0;
    [nameLabel release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTotalCheckinLabel:nil];
    [self setUniqueFriendsLabel:nil];
    [self setNonUniqueFriendsLabel:nil];
    [self setScoreLabel:nil];
    [self setLevelLabel:nil];
    [self setLevelProgressBar:nil];
    [self setLevelPercentLabel:nil];
    [self setNameLabel:nil];
    [super viewDidUnload];
}
@end
