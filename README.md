# RSOAuthEngine
By Rodrigo Sieiro - [@rsieiro](http://twitter.com/rsieiro)  
[http://rodrigo.sharpcube.com](http://rodrigo.sharpcube.com)

## About

**RSOAuthEngine** is an ARC based OAuth engine for [MKNetworkKit](https://github.com/MugunthKumar/MKNetworkKit). It supports OAuth 1.0a and it's fully compatible with MKNetworkKit existing classes, allowing you to simply inherit `RSOAuthEngine` instead of `MKNetworkEngine` to get OAuth support.

## Usage

If you already have a project using MKNetworkKit, just add the contents of the `RSOAuthEngine` directory to your project and change all classes that inherit from `MKNetworkEngine` to inherit from `RSOAuthEngine` instead. Whenever you need to send an OAuth signed request, replace calls to `enqueueOperation` with `enqueueSignedOperation`.

If you're not currently using MKNetworkKit, follow the instructions to add it to your project [here](http://blog.mugunthkumar.com/products/ios-framework-introducing-mknetworkkit/) first, then add **RSOAuthEngine** as written in the previous paragraph. **Important**: although not mentioned in the instructions, MKNetworkKit also requires Security.framework.

### Usage Details

A common OAuth flow using **RSOAuthEngine** should go like this:

1. Create a class that inherits from **RSOAuthEngine**.
2. Init your class using one of the defined initializers that include your Consumer Key and Secret.
3. Send a signed operation to get a request token.
4. Fill the request token using `fillTokenWithResponseBody:type` (use `RSOAuthRequestToken` as type).
5. Redirect the user to the authorization page and wait for the callback.
6. Fill the request token (again) using `fillTokenWithResponseBody:type` (use `RSOAuthRequestToken` as type), this time using the parameters received in the callback.
7. Send another request to get an access token.
8. Fill the access token using `fillTokenWithResponseBody:type` (use `RSOAuthAccessToken` as type).
9. From now on, all requests sent with `enqueueSignedOperation` will be signed with your tokens.

Alternatively you could use `setAccessToken:secret` after initialization to define a previously stored access token. If you need or want to use xAuth instead of the request token/authorize workflow, please take a look at the Instapaper demo.

## Twitter Demo

<table>
  <tr>
	<td width="300">
<img src="https://github.com/rsieiro/RSOAuthEngine/raw/master/screenshot.png" alt="Screenshot" width="396" />
	</td>
	<td valign="top">
<h3>About</h3>

<p>This sample project demonstrates how to use <strong>RSOAuthEngine</strong> to authenticate with Twitter. It includes a basic engine that implements Twitter's OAuth authentication flow and allows you to post a tweet. It also shows you how to persist the OAuth access token in the Keychain. The Twitter engine should not be considered production code, and is only included to demonstrate <strong>RSOAuthEngine</strong>.</p>

<h3>Building</h3>

<p>To build the demo project, follow these steps:</p>

<ol>
<li>In the project directory, run <code>git submodule update --init</code> to retrieve MKNetworkKit (added to the project as a submodule).</li>
<li>Put your consumer key and secret at the top of <code>RSTwitterEngine.m</code> and remove the <code>#error</code> macro. If you don't have a consumer key/secret, register an app at <a href="https://dev.twitter.com/apps">https://dev.twitter.com/apps</a> to get a pair. <strong>Important</strong>: you need to add a dummy callback URL to your app when registering, otherwise Twitter won't allow you to send a callback URL in the OAuth request.</li>
</ol>

<h3>Tips</h3>

<p>Swipe from left to right in the status message to clear previously stored OAuth tokens.</p>
	</td>
  </tr>
</table>

## Instapaper Demo

<table>
  <tr>
	<td width="300">
<img src="https://github.com/rsieiro/RSOAuthEngine/raw/master/screenshot-2.png" alt="Screenshot" width="396" />
	</td>
	<td valign="top">
<h3>About</h3>

<p>This sample project demonstrates how to use <strong>RSOAuthEngine</strong> with xAuth to authenticate with Instapaper. It includes a basic engine that implements Instapapers's xAuth authentication flow and allows you to add a bookmark to your account. It also shows you how to persist the OAuth access token in the Keychain. The Instapaper engine should not be considered production code, and is only included to demonstrate <strong>RSOAuthEngine</strong>.</p>

<h3>Building</h3>

<p>To build the demo project, follow these steps:</p>

<ol>
<li>In the project directory, run <code>git submodule update --init</code> to retrieve MKNetworkKit (added to the project as a submodule).</li>
<li>Put your consumer key and secret at the top of <code>RSInstapaperEngine.m</code> and remove the <code>#error</code> macro. If you don't have a consumer key/secret, register an app at <a href="http://www.instapaper.com/main/request_oauth_consumer_token">this page</a> to get a pair. <strong>Important</strong>: most Instapaper API methods are only available to users with a Subscription account.</li>
</ol>

<h3>Tips</h3>

<p>Swipe from left to right in the status message to clear previously stored OAuth tokens.</p>
	</td>
  </tr>
</table>

## Compatibility

Currently this engine has been tested with Twitter and Instapaper. If you use **RSOAuthEngine** to implement OAuth authentication with another service, please let me know so I can update this session.

## License

**RSOAuthEngine** is licensed under the MIT License. Please give me some kind of attribution if you use it in your project, such as a "thanks" note somewhere. I'd also love to know if you use my code, please drop me a line if you do!

Full license text follows:

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

## Acknowledgments

**RSOAuthEngine** may contain code from [ASI-HTTP-Request-OAuth](https://github.com/keybuk/asi-http-request-oauth) by Scott James Remnant and the iPhone version of [OAuthConsumer](https://github.com/jdg/oauthconsumer) by Jonathan George. I used bits and pieces of the code from both projects as references to write this engine.