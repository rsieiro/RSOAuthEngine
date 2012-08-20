//
//  ViewController.m
//  InstapaperDemo
//
//  Created by Rodrigo Sieiro on 12/13/11.
//  Copyright (c) 2011-2020 Rodrigo Sieiro <rsieiro@sharpcube.com>. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "ViewController.h"

@implementation ViewController

@synthesize instapaperEngine = _instapaperEngine;
@synthesize authView = _authView;
@synthesize urlTextField = _urlTextField;
@synthesize titleTextField = _titleTextField;
@synthesize textView = _textView;
@synthesize sendButton = _sendButton;
@synthesize clearButton = _clearButton;
@synthesize statusLabel = _statusLabel;
@synthesize scrollView = _scrollView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:self.view.window];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:self.view.window];    
    
    _keyboardIsShown = NO;
    self.scrollView.contentSize = CGSizeMake(320, 388);
    self.instapaperEngine = [[RSInstapaperEngine alloc] initWithDelegate:self];
    
    // A right swipe on the status label will clear the stored token
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.numberOfTouchesRequired = 1;
    [self.statusLabel.superview addGestureRecognizer:swipeRight];
    
    // Check if the user is already authenticated
    if (self.instapaperEngine.isAuthenticated) {
        self.statusLabel.text = [NSString stringWithFormat:@"Signed in as %@.", self.instapaperEngine.screenName];
    } else {
        self.statusLabel.text = @"Not signed in.";
    }
    
    [self.urlTextField becomeFirstResponder];
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setSendButton:nil];
    [self setInstapaperEngine:nil];
    [self setStatusLabel:nil];
    [self setScrollView:nil];
    [self setUrlTextField:nil];
    [self setTitleTextField:nil];
    [self setClearButton:nil];
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillShowNotification 
                                                  object:nil];
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];    

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Keyboard Show/Hide Notifications

- (void)keyboardWillShow:(NSNotification *)n
{
    if (_keyboardIsShown) return;
    
    NSDictionary* userInfo = [n userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.size.height -= keyboardSize.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.scrollView setFrame:viewFrame];
    }];
    
    _keyboardIsShown = YES;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    NSDictionary* userInfo = [n userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.size.height += keyboardSize.height;

    [UIView animateWithDuration:0.3 animations:^{
        [self.scrollView setFrame:viewFrame];
    }];

    _keyboardIsShown = NO;
}

#pragma mark - UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.urlTextField) {
        [self.titleTextField becomeFirstResponder];
    } else if (textField == self.titleTextField) {
        [self.textView becomeFirstResponder];
    }
    
    return YES;
}

#pragma mark - RSInstapaperEngine Delegate Methods

- (void)instapaperEngineNeedsAuthentication:(RSInstapaperEngine *)engine
{
    self.authView = [[AuthViewController alloc] initWithNibName:@"AuthViewController" bundle:nil];
    self.authView.delegate = self;
    
    [self presentModalViewController:self.authView animated:YES];
}

- (void)instapaperEngine:(RSInstapaperEngine *)engine statusUpdate:(NSString *)message
{
    self.statusLabel.text = message;
}

#pragma mark - WebViewController Delegate Methods

- (void)cancelAuthentication
{
    [self dismissModalViewControllerAnimated:YES];
    if (self.instapaperEngine) [self.instapaperEngine cancelAuthentication];
}

- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password
{
    [self dismissModalViewControllerAnimated:YES];
    if (self.instapaperEngine) [self.instapaperEngine authenticateWithUsername:username password:password];
}

#pragma mark - Custom Methods

- (void)swipedRight:(UIGestureRecognizer *)recognizer
{
    if (self.instapaperEngine) [self.instapaperEngine forgetStoredToken];
    self.statusLabel.text = @"Not signed in.";
}

- (IBAction)addBookmark:(id)sender
{
    if (self.instapaperEngine)
    {
        self.sendButton.enabled = NO;
        self.clearButton.enabled = NO;
        
        // Instapaper requires full URLs
        if (![self.urlTextField.text hasPrefix:@"http://"])
            self.urlTextField.text = [NSString stringWithFormat:@"http://%@", self.urlTextField.text];
        
        // TODO: Validate the contents of each field
        [self.instapaperEngine bookmarkURL:self.urlTextField.text
                                     title:self.titleTextField.text
                               description:self.textView.text 
                           completionBlock:^(NSError *error)
         {
             if (error) {
                 NSString *errorDescription;
                 
                 // TODO: check for other type of errors
                 if (error.code == 401) {
                     errorDescription = @"Authentication failed.";
                 } else {
                     errorDescription = [error localizedDescription];
                 }
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:errorDescription
                                                                delegate:nil
                                                       cancelButtonTitle:@"Dismiss"
                                                       otherButtonTitles:nil];
                 [alert show];
             } else {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"InstaAdd!"
                                                                 message:@"Bookmark added successfully!"
                                                                delegate:nil
                                                       cancelButtonTitle:@"Dismiss"
                                                       otherButtonTitles:nil];
                 [alert show];
                 
                 [self clearFields:nil];
             }
             
             self.sendButton.enabled = YES;
             self.clearButton.enabled = YES;
             
             if (self.instapaperEngine.isAuthenticated) {
                 self.statusLabel.text = [NSString stringWithFormat:@"Signed in as %@.", self.instapaperEngine.screenName];
             } else {
                 self.statusLabel.text = @"Not signed in.";
             }
         }];
    }
}

- (IBAction)clearFields:(id)sender
{
    self.urlTextField.text = @"";
    self.titleTextField.text = @"";
    self.textView.text = @"";
    
    [self.urlTextField becomeFirstResponder];
}

@end
