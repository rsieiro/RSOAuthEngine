//
//  RSOAuthEngine.h
//  RSOAuthEngine
//
//  Created by Rodrigo Sieiro on 12/11/11.
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

#import "MKNetworkEngine.h"

typedef enum _RSOAuthTokenType
{
    RSOAuthRequestToken,
    RSOAuthRequestAccessToken,
    RSOAuthAccessToken,
}
RSOAuthTokenType;

typedef enum _RSOOAuthSignatureMethod {
    RSOAuthPlainText,
    RSOAuthHMAC_SHA1,
} RSOAuthSignatureMethod;

typedef enum _RSOAuthParameterStyle {
    RSOAuthParameterStyleHeader,
    RSOAuthParameterStylePostBody,    
    RSOAuthParameterStyleQueryString
} RSOAuthParameterStyle;

@interface RSOAuthEngine : MKNetworkEngine
{
    @private
    RSOAuthTokenType _tokenType;
    RSOAuthSignatureMethod _signatureMethod;
    NSString *_consumerSecret;
    NSString *_tokenSecret;
    NSString *_callbackURL;
    NSString *_verifier;
    NSMutableDictionary *_oAuthValues;
    NSMutableDictionary *_customValues;
}

@property (readonly) RSOAuthTokenType tokenType;
@property (readonly) RSOAuthSignatureMethod signatureMethod;
@property (readonly) NSString *consumerKey;
@property (readonly) NSString *consumerSecret;
@property (readonly) NSString *callbackURL;
@property (readonly) NSString *token;
@property (readonly) NSString *tokenSecret;
@property (readonly) NSString *verifier;

@property (nonatomic, assign) RSOAuthParameterStyle parameterStyle;

- (id)initWithHostName:(NSString *)hostName 
    customHeaderFields:(NSDictionary *)headers
       signatureMethod:(RSOAuthSignatureMethod)signatureMethod
           consumerKey:(NSString *)consumerKey
        consumerSecret:(NSString *)consumerSecret
           callbackURL:(NSString *)callbackURL;

- (id)initWithHostName:(NSString *)hostName
    customHeaderFields:(NSDictionary *)headers
       signatureMethod:(RSOAuthSignatureMethod)signatureMethod
           consumerKey:(NSString *)consumerKey
        consumerSecret:(NSString *)consumerSecret;

- (BOOL)isAuthenticated;
- (void)resetOAuthToken;
- (NSString *)customValueForKey:(NSString *)key;
- (void)fillTokenWithResponseBody:(NSString *)body type:(RSOAuthTokenType)tokenType;
- (void)setAccessToken:(NSString *)token secret:(NSString *)tokenSecret;
- (void)signRequest:(MKNetworkOperation *)request;
- (void)enqueueSignedOperation:(MKNetworkOperation *)op;
- (NSString *)generateXOAuthStringForURL:(NSString *)url method:(NSString *)method;

@end
