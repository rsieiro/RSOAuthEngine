//
//  RSInstapaperEngine.m
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

#import "RSInstapaperEngine.h"

// Never share this information
#error  Put your Consumer Key and Secret here, then remove this error
#define IP_CONSUMER_KEY @""
#define IP_CONSUMER_SECRET @""

// Default instapaper hostname and paths
#define IP_HOSTNAME @"www.instapaper.com"
#define IP_ACCESS_TOKEN @"api/1/oauth/access_token"
#define IP_ADD_BOOKMARK @"api/1/bookmarks/add"

@interface RSInstapaperEngine ()

- (void)removeOAuthTokenFromKeychain;
- (void)storeOAuthTokenInKeychain;
- (void)retrieveOAuthTokenFromKeychain;

@end

@implementation RSInstapaperEngine

@synthesize delegate = _delegate;

#pragma mark - Read-only Properties

- (NSString *)screenName
{
    return _screenName;
}

#pragma mark - Initialization

- (id)initWithDelegate:(id <RSInstapaperEngineDelegate>)delegate
{
    self = [super initWithHostName:IP_HOSTNAME
                customHeaderFields:nil
                   signatureMethod:RSOAuthHMAC_SHA1
                       consumerKey:IP_CONSUMER_KEY
                    consumerSecret:IP_CONSUMER_SECRET];
    
    if (self) {
        _oAuthCompletionBlock = nil;
        _screenName = nil;
        self.delegate = delegate;
        
        // Retrieve OAuth access token (if previously stored)
        [self retrieveOAuthTokenFromKeychain];
    }
    
    return self;
}

#pragma mark - OAuth Access Token store/retrieve

- (void)removeOAuthTokenFromKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnAttributes,
                                          nil];
    
    // If there's a token stored for this user, delete it
    SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
}

- (void)storeOAuthTokenInKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnAttributes,
                                          nil];
    
    CFTypeRef resData = NULL;
    
    // If there's a token stored for this user, delete it first
    SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
    
    // Build the token dictionary
    NSMutableDictionary *tokenDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            self.token, @"oauth_token",
                                            self.tokenSecret, @"oauth_token_secret",
                                            self.screenName, @"screen_name",
                                            nil];
    
    // Add the token dictionary to the query
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:tokenDictionary] 
                      forKey:(__bridge_transfer NSString *)kSecValueData];
    
    // Add the token data to the keychain
    // Even if we never use resData, replacing with NULL in the call throws EXC_BAD_ACCESS
    SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, (CFTypeRef *) &resData);
}

- (void)retrieveOAuthTokenFromKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnData,
                                          kSecMatchLimitOne, kSecMatchLimit,
                                          nil];
    
    // Get the token data from the keychain
    CFTypeRef resData = NULL;
    
    // Get the token dictionary from the keychain
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef) keychainQuery, (CFTypeRef *) &resData) == noErr)
    {
        NSData *resultData = (__bridge_transfer NSData *)resData;
        
        if (resultData)
        {
            NSMutableDictionary *tokenDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
            
            if (tokenDictionary) {
                [self setAccessToken:[tokenDictionary objectForKey:@"oauth_token"]
                              secret:[tokenDictionary objectForKey:@"oauth_token_secret"]];
                
                _screenName = [tokenDictionary objectForKey:@"screen_name"];
            }
        }
    }
}

#pragma mark - OAuth Authentication Flow

- (void)authenticateWithCompletionBlock:(RSInstapaperEngineCompletionBlock)completionBlock
{
    // First we reset the OAuth token, so we won't send previous tokens in the request
    [self resetOAuthToken];
    
    // Store the Completion Block to call after Authenticated
    _oAuthCompletionBlock = [completionBlock copy];
    
    [self.delegate instapaperEngine:self statusUpdate:@"Waiting for user authorization..."];
    [self.delegate instapaperEngineNeedsAuthentication:self];
}

- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password
{
    // Fill the post body with the xAuth parameters
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       username, @"x_auth_username",
                                       password, @"x_auth_password",
                                       @"client_auth", @"x_auth_mode",
                                       nil];
    
    // Get the access token using xAuth
    MKNetworkOperation *op = [self operationWithPath:IP_ACCESS_TOKEN
                                              params:postParams
                                          httpMethod:@"POST"
                                                 ssl:YES];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        // Fill the access token with the returned data
        [self fillTokenWithResponseBody:[completedOperation responseString] type:RSOAuthAccessToken];
        
        // Set the user's screen name
        _screenName = [username copy];
        
        // Store the OAuth access token
        [self storeOAuthTokenInKeychain];
        
        // Finished, return to previous method
        if (_oAuthCompletionBlock) _oAuthCompletionBlock(nil);
        _oAuthCompletionBlock = nil;
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (_oAuthCompletionBlock) _oAuthCompletionBlock(error);
        _oAuthCompletionBlock = nil;
    }];
    
    [self.delegate instapaperEngine:self statusUpdate:@"Authenticating..."];
    [self enqueueSignedOperation:op];
}

- (void)cancelAuthentication
{
    NSDictionary *ui = [NSDictionary dictionaryWithObjectsAndKeys:@"Authentication cancelled.", NSLocalizedDescriptionKey, nil];
    NSError *error = [NSError errorWithDomain:@"com.sharpcube.RSInstapaperEngine.ErrorDomain" code:401 userInfo:ui];
    
    if (_oAuthCompletionBlock) _oAuthCompletionBlock(error);
    _oAuthCompletionBlock = nil;
}

- (void)forgetStoredToken
{
    [self removeOAuthTokenFromKeychain];
    [self resetOAuthToken];
    _screenName = nil;
}

#pragma mark - Public Methods

- (void)bookmarkURL:(NSString *)url
              title:(NSString *)title
        description:(NSString *)description
    completionBlock:(RSInstapaperEngineCompletionBlock)completionBlock
{
    if (!self.isAuthenticated) {
        [self authenticateWithCompletionBlock:^(NSError *error) {
            if (error) {
                // Authentication failed, return the error
                completionBlock(error);
            } else {
                // Authentication succeeded, call this method again
                [self bookmarkURL:url
                            title:title
                      description:description
                  completionBlock:completionBlock];
            }
        }];
        
        // This method will be called again once the authentication completes
        return;
    }
    
    // Fill the post body with the tweet
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       url, @"url",
                                       title, @"title",
                                       description, @"description",
                                       nil];

    // Send the bookmark to Instapaper
    MKNetworkOperation *op = [self operationWithPath:IP_ADD_BOOKMARK
                                              params:postParams
                                          httpMethod:@"POST"
                                                 ssl:YES];
    
    // TODO: Actually check the response to get the data or the error
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionBlock(nil);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        completionBlock(error);
    }];
    
    [self.delegate instapaperEngine:self statusUpdate:@"Adding the bookmark..."];
    [self enqueueSignedOperation:op];
}

@end
