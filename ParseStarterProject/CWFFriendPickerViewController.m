//
//  CWFFriendPickerViewController.m
//  CWF
//
//  Created by HengHong on 22/7/12.
//
//

#import "CWFFriendPickerViewController.h"


@implementation CWFFriendPickerViewController
@synthesize friendTableView;
@synthesize pickerTextField;
@synthesize myRequest;
@synthesize FBfriendsArray,friendsArray;
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
        self.myRequest = [[PFFacebookUtils facebook] requestWithGraphPath:@"me/friends" andDelegate:self];
    FBfriendsArray = [[NSMutableArray alloc]init];
    friendsArray = [[NSMutableArray alloc]init];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)request:(PF_FBRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"%@",response);
    
    
    
}
- (void)request:(PF_FBRequest *)request didLoad:(id)result {
    //NSString* photoid;
    
    NSLog(@"result");
    NSArray* fbfriends = [result objectForKey:@"data"];
    
    [FBfriendsArray removeAllObjects];
    for (NSDictionary* obj in fbfriends) {
        NSMutableDictionary* newFBfriend = [[NSMutableDictionary alloc]init];
        [newFBfriend setObject:[obj objectForKey:@"id"] forKey:@"id"];
        [newFBfriend setObject:[obj objectForKey:@"name"] forKey:@"name"];
        [FBfriendsArray addObject:newFBfriend];
        [newFBfriend release];
    }
    [friendsArray addObjectsFromArray:FBfriendsArray];
    [pickerTextField becomeFirstResponder];
    [friendTableView reloadData];
    
//    //  NSLog(@"fbfriends array = %@",FBfriendsArray);
//    [friendsArray addObjectsFromArray:FBfriendsArray];
//    [taggerTable reloadData];
//    [MBProgressHUD hideHUDForView:self.view animated:YES];
//    taggerTable.hidden=NO;
//    [taggerTextField becomeFirstResponder];
    
    
}
- (BOOL) textField: (UITextField *) textField shouldChangeCharactersInRange: (NSRange) range replacementString: (NSString *) string
{
    
    [friendsArray removeAllObjects];
    NSRange textRange;
    for (NSMutableDictionary* user in FBfriendsArray) {
        
        textRange =[[[user objectForKey:@"name"] lowercaseString] rangeOfString:[pickerTextField.text lowercaseString]];
        if(textRange.location != NSNotFound)
        {
            [friendsArray addObject:user];
        }
        
    }
    if ([pickerTextField.text isEqualToString:@""]) {
        [friendsArray addObjectsFromArray:FBfriendsArray];
        
    }
    [friendTableView reloadData];
    
    return YES;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [friendsArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"mycell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    
    
    cell.textLabel.text =[[friendsArray objectAtIndex:indexPath.row]objectForKey:@"name"];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate FPDidReturnWithFriendUID:[NSString stringWithFormat:@"%@",[[friendsArray objectAtIndex:indexPath.row]objectForKey:@"id"]] andName:[NSString stringWithFormat:@"%@",[[friendsArray objectAtIndex:indexPath.row]objectForKey:@"name"]]];
}

-(void)dealloc
{
    [friendTableView release];
    [friendsArray release];
    [FBfriendsArray release];
    [pickerTextField release];
    [super dealloc];
    if( myRequest ) {
        [[myRequest connection] cancel];
        [myRequest release];
    }
}

- (void)viewDidUnload {
    [self setFriendTableView:nil];
    [self setPickerTextField:nil];
    [super viewDidUnload];
}
@end
