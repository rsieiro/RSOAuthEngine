//
//  ViewController.h
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

#import <UIKit/UIKit.h>
#import "RSInstapaperEngine.h"
#import "AuthViewController.h"

@interface ViewController : UIViewController <RSInstapaperEngineDelegate, AuthViewControllerDelegate, UITextFieldDelegate>
{
    BOOL _keyboardIsShown;
}

@property (strong, nonatomic) RSInstapaperEngine *instapaperEngine;
@property (strong, nonatomic) AuthViewController *authView;

@property (unsafe_unretained, nonatomic) IBOutlet UITextField *urlTextField;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *titleTextField;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *textView;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *statusLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)addBookmark:(id)sender;
- (IBAction)clearFields:(id)sender;
- (void)swipedRight:(UIGestureRecognizer *)recognizer;

@end
