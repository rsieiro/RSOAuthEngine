//
//  RSInstapaperEngine.h
//  RSOAuthEngine
//
//  Created by Rodrigo Sieiro on 12/8/11.
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

#import "RSOAuthEngine.h"

@protocol RSInstapaperEngineDelegate;

typedef void (^RSInstapaperEngineCompletionBlock)(NSError *error);

@interface RSInstapaperEngine : RSOAuthEngine
{
    RSInstapaperEngineCompletionBlock _oAuthCompletionBlock;
    NSString *_screenName;
}

@property (assign) id <RSInstapaperEngineDelegate> delegate;
@property (readonly) NSString *screenName;

- (id)initWithDelegate:(id <RSInstapaperEngineDelegate>)delegate;
- (void)authenticateWithCompletionBlock:(RSInstapaperEngineCompletionBlock)completionBlock;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;
- (void)cancelAuthentication;
- (void)forgetStoredToken;

- (void)bookmarkURL:(NSString *)url
              title:(NSString *)title
        description:(NSString *)description
    completionBlock:(RSInstapaperEngineCompletionBlock)completionBlock;

@end

@protocol RSInstapaperEngineDelegate <NSObject>

- (void)instapaperEngineNeedsAuthentication:(RSInstapaperEngine *)engine;
- (void)instapaperEngine:(RSInstapaperEngine *)engine statusUpdate:(NSString *)message;

@end