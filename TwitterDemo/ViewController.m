//
//  ViewController.m
//  TwitterDemo
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.twitterEngine = [[RSTwitterEngine alloc] initWithDelegate:self];
    
    // A right swipe on the status label will clear the stored token
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.numberOfTouchesRequired = 1;
    [self.statusLabel.superview addGestureRecognizer:swipeRight];
    
    // Check if the user is already authenticated
    if (self.twitterEngine.isAuthenticated) {
        self.statusLabel.text = [NSString stringWithFormat:@"Signed in as @%@.", self.twitterEngine.screenName];
    } else {
        self.statusLabel.text = @"Not signed in.";
    }
    
    [self.textView becomeFirstResponder];
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setSendButton:nil];
    [self setTwitterEngine:nil];
    [self setStatusLabel:nil];

    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - RSTwitterEngine Delegate Methods

- (void)twitterEngine:(RSTwitterEngine *)engine needsToOpenURL:(NSURL *)url
{
    self.webView = [[WebViewController alloc] initWithURL:url];
    self.webView.delegate = self;
    
    [self presentModalViewController:self.webView animated:YES];
}

- (void)twitterEngine:(RSTwitterEngine *)engine statusUpdate:(NSString *)message
{
    self.statusLabel.text = message;
}

#pragma mark - WebViewController Delegate Methods

- (void)dismissWebView
{
    [self dismissModalViewControllerAnimated:YES];
    if (self.twitterEngine) [self.twitterEngine cancelAuthentication];
}

- (void)handleURL:(NSURL *)url
{
    [self dismissModalViewControllerAnimated:YES];
    
    if ([url.query hasPrefix:@"denied"]) {
        if (self.twitterEngine) [self.twitterEngine cancelAuthentication];
    } else {
        if (self.twitterEngine) [self.twitterEngine resumeAuthenticationFlowWithURL:url];
    }
}

#pragma mark - Custom Methods

- (void)swipedRight:(UIGestureRecognizer *)recognizer
{
    if (self.twitterEngine) [self.twitterEngine forgetStoredToken];
    self.statusLabel.text = @"Not signed in.";
}

- (IBAction)sendTweet:(id)sender
{
    if (self.twitterEngine)
    {
        self.sendButton.enabled = NO;
        
        [self.twitterEngine sendTweet:self.textView.text withCompletionBlock:^(NSError *error) {
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickTweet!"
                                                                message:@"Tweet posted successfully!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                [alert show];
                
                self.textView.text = @"";
            }
            
            self.sendButton.enabled = YES;

            if (self.twitterEngine.isAuthenticated) {
                self.statusLabel.text = [NSString stringWithFormat:@"Signed in as @%@.", self.twitterEngine.screenName];
            } else {
                self.statusLabel.text = @"Not signed in.";
            }
        }];
    }
}

@end
