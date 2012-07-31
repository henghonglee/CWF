//
//  CWFOnBoardingViewController.m
//  CWF
//
//  Created by HengHong on 17/7/12.
//
//

#import "CWFOnBoardingViewController.h"

@interface CWFOnBoardingViewController ()

@end

@implementation CWFOnBoardingViewController
@synthesize userCheckins,checkin_fb_ids_Array,checkinPFobjArray,currEndpointURL;

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
    checkin_fb_ids_Array = [[NSMutableArray alloc]init];
            checkinPFobjArray = [[NSMutableArray alloc]init];

    retrievedCount=0;
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)fbConnect:(id)sender {
    [PFFacebookUtils facebook].accessToken=nil;
    if (![PFFacebookUtils facebook].accessToken) {
        NSArray* permissions = [[NSArray alloc]initWithObjects:@"user_checkins",@"friends_checkins",@"user_about_me",@"user_activities",@"user_birthday",@"user_events",@"user_groups",@"user_interests",@"user_likes",@"user_location",@"user_photos",@"email",nil];
        
        [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
            if (!user) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"logged in");
                NSMutableDictionary* reqParams = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"profileRequest",@"type", nil];
                [[PFFacebookUtils facebook] requestWithGraphPath:@"/me?fields=id,name,first_name,last_name,gender,birthday" andParams:reqParams andDelegate:self];
                
            }
                    [permissions release];
        }];

    }else{
//        NSLog(@"already logged in");
//        //still get info if hes got access token
//        NSMutableDictionary* reqParams = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"profileRequest",@"type", nil];
//        [[PFFacebookUtils facebook] requestWithGraphPath:@"/me?fields=id,name,first_name,last_name,gender,birthday" andParams:reqParams andDelegate:self];
        InstagramViewController* instVC = [[InstagramViewController alloc]init];
        [self presentModalViewController:instVC animated:YES];
        [instVC setSelectedIndex:2];
        [instVC release];
        
    }

}
-(void)viewDidAppear:(BOOL)animated
{
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
   
    if ([[request.params objectForKey:@"type"] isEqualToString:@"profileRequest"]) {
        //FIXME:picture not working! may need to use FQL
        [[PFUser currentUser]setObject:[result objectForKey:@"id"] forKey:@"fb_id"];
        
        [[PFUser currentUser]setObject:[result objectForKey:@"first_name"] forKey:@"first_name"];
        [[PFUser currentUser]setObject:[result objectForKey:@"last_name"] forKey:@"last_name"];
        [[PFUser currentUser]setObject:[result objectForKey:@"gender"] forKey:@"gender"];
        [[PFUser currentUser]setObject:[result objectForKey:@"name"] forKey:@"full_name"];
        
        //calculate age
        //*************
        if ([result objectForKey:@"birthday"]) {
        [[PFUser currentUser] setObject:[result objectForKey:@"birthday"] forKey:@"birthdate"];
        NSString *trimmedString=[((NSString*)[result objectForKey:@"birthday"]) substringFromIndex:[((NSString*)[result objectForKey:@"birthday"]) length]-4];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY"];
        NSString *yearString = [formatter stringFromDate:[NSDate date]];
        [formatter release];
        int age = [yearString intValue]-[trimmedString intValue];
        [[PFUser currentUser] setObject:[NSNumber numberWithInt:age] forKey:@"age"];
        }
        //************
        
        [[PFUser currentUser]saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
           [self performSelector:@selector(fbGraphCall:) withObject:@"/me/checkins?limit=20&fields=id,place,created_time,tags,from"];
        }];
    }
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

            
            
            [checkin_fb_ids_Array addObject:[object objectForKey:@"id"]];

                [queryForCheckin getFirstObjectInBackgroundWithBlock:^(PFObject *checkedin, NSError *error) {
                    
                    if (!checkedin) {
                      
                        //FIXME:potential bug as user first adds checkins to not be able to detect clashes
                        
                        PFQuery* checkValidity = [PFQuery queryWithClassName:@"CheckIn"];
                        PFGeoPoint* checkinGP = [PFGeoPoint geoPointWithLatitude:((double)[[[object objectForKey:@"location"] objectForKey:@"latitude"]doubleValue]) longitude:((double)[[[object objectForKey:@"location"] objectForKey:@"longitude"]doubleValue])];
                        
                        //TODO:checkin now set to THAT point , should be a box, find out how much is meters in lat/lon and add that to the geopoint
                        
                        [checkValidity whereKey:@"checkin_geopoint" nearGeoPoint:checkinGP withinKilometers:0.5];
                        
                        //checkin owner cant be the same
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
                                    
                                    //add checkins to the user model uniquely
                                    [[PFUser currentUser]addUniqueObjectsFromArray:checkin_fb_ids_Array forKey:@"checkin_fb_ids"];
                                    //TODO:also set user's last updated datetimestamp! so we can crawl from there nxt time
                                    [[PFUser currentUser]saveInBackground];
                                    
                                    
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
        for (PFObject* checkin in userCheckins) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSString stringWithFormat:@"SELECT categories , pic_small,type,location FROM page WHERE page_id IN (SELECT page_id FROM checkin WHERE checkin_id=%@)",[checkin objectForKey:@"fb_id"]], @"query",@"categoryRequest",@"type",[checkin objectForKey:@"fb_id"],@"fb_id",nil];
            [[PFFacebookUtils facebook] requestWithMethodName:@"fql.query"
                                                    andParams:params
                                                andHttpMethod:@"POST"
                                                  andDelegate:self];
        }
        InstagramViewController* instVC = [[InstagramViewController alloc]init];
        [self presentModalViewController:instVC animated:YES];
        [instVC setSelectedIndex:2];
        [instVC release];
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
        if (checkCount == [userCheckins count]) {
            [PFObject saveAllInBackground:userCheckins block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    InstagramViewController* instVC = [[InstagramViewController alloc]init];
                    [self presentModalViewController:instVC animated:YES];
                    [instVC setSelectedIndex:2];
                    [instVC release];
                    NSLog(@"done saving all");
                }
            }];
        }
    }

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
