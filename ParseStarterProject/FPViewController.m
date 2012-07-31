/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FPAppDelegate.h"
#import "FPViewController.h"

// FBSample logic
// We need to handle some of the UX events related to friend selection, and so we declare
// that we implement the FBFriendPickerDelegate here; the delegate lets us filter the view
// as well as handle selection events
@interface FPViewController () 

@property (strong, nonatomic) IBOutlet UITextView *selectedFriendsView;
@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;

- (void)doneButtonWasPressed:(id)sender;
- (void)cancelButtonWasPressed:(id)sender;
- (void)fillTextBoxAndDismiss:(NSString *)text;

@end

@implementation FPViewController

@synthesize selectedFriendsView = _friendResultText;
@synthesize friendPickerController = _friendPickerController;

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // FBSample logic
    // if the session is open, then load the data for our view controller
    if (!FBSession.activeSession.isOpen) {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
                                                         FBSessionState state,
                                                         NSError *error) {
            switch (state) {
                case FBSessionStateClosedLoginFailed:
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:error.localizedDescription
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)viewDidUnload {
    self.selectedFriendsView = nil;
    self.friendPickerController = nil;
    
    [super viewDidUnload];
}

#pragma mark UI handlers

- (IBAction)pickFriendsButtonClick:(id)sender {
        
    // Create friend picker, and get data loaded into it.
    FBFriendPickerViewController *friendPicker = [[FBFriendPickerViewController alloc] init];
    self.friendPickerController = friendPicker;

    [friendPicker loadData];
    
    // Create navigation controller related UI for the friend picker.
    friendPicker.navigationItem.title = @"Pick Friends";
    friendPicker.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
                                                      initWithTitle:@"Done" 
                                                      style:UIBarButtonItemStyleBordered 
                                                      target:self 
                                                      action:@selector(doneButtonWasPressed:)];
    friendPicker.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
                                                     initWithTitle:@"Cancel" 
                                                     style:UIBarButtonItemStyleBordered 
                                                     target:self 
                                                     action:@selector(cancelButtonWasPressed:)];
    
    // Make current.
    [self.navigationController pushViewController:friendPicker animated:YES];
}

- (void)doneButtonWasPressed:(id)sender {
    NSMutableString *text = [[NSMutableString alloc] init];
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];
    }
    
    [self fillTextBoxAndDismiss:text];
}

- (void)cancelButtonWasPressed:(id)sender {
    [self fillTextBoxAndDismiss:@"<Cancelled>"];
}

- (void)fillTextBoxAndDismiss:(NSString *)text {
    self.selectedFriendsView.text = text;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

@end
