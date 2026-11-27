# news_api_client.api.EngagementApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bookmark**](EngagementApi.md#bookmark) | **PUT** /api/v1/engagement/posts/{post_id}/bookmark | 
[**commentCreate**](EngagementApi.md#commentcreate) | **POST** /api/v1/engagement/posts/{post_id}/comments | 
[**commentDelete**](EngagementApi.md#commentdelete) | **DELETE** /api/v1/engagement/comments/{comment_id} | 
[**commentLike**](EngagementApi.md#commentlike) | **PUT** /api/v1/engagement/comments/{comment_id}/like | 
[**commentUnlike**](EngagementApi.md#commentunlike) | **DELETE** /api/v1/engagement/comments/{comment_id}/like | 
[**comments**](EngagementApi.md#comments) | **GET** /api/v1/engagement/posts/{post_id}/comments | 
[**engagementState**](EngagementApi.md#engagementstate) | **GET** /api/v1/engagement/state | 
[**follow**](EngagementApi.md#follow) | **PUT** /api/v1/engagement/follows/{kind}/{target} | 
[**like**](EngagementApi.md#like) | **PUT** /api/v1/engagement/posts/{post_id}/like | 
[**opened**](EngagementApi.md#opened) | **POST** /api/v1/engagement/posts/{post_id}/opened | 
[**readers**](EngagementApi.md#readers) | **GET** /api/v1/engagement/posts/{post_id}/readers | 
[**unbookmark**](EngagementApi.md#unbookmark) | **DELETE** /api/v1/engagement/posts/{post_id}/bookmark | 
[**unfollow**](EngagementApi.md#unfollow) | **DELETE** /api/v1/engagement/follows/{kind}/{target} | 
[**unlike**](EngagementApi.md#unlike) | **DELETE** /api/v1/engagement/posts/{post_id}/like | 


# **bookmark**
> Bookmarked bookmark(postId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.bookmark(postId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->bookmark: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 

### Return type

[**Bookmarked**](Bookmarked.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentCreate**
> Comment commentCreate(postId, newCommentRequest)



GET: a page of comments (or one comment's replies). POST: a new one. Signed-in readers also see their own held comments and which they liked, so their answers are private; everyone else's may be kept 15 s.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final NewCommentRequest newCommentRequest = ; // NewCommentRequest | 

try {
    final response = api.commentCreate(postId, newCommentRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->commentCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 
 **newCommentRequest** | [**NewCommentRequest**](NewCommentRequest.md)|  | 

### Return type

[**Comment**](Comment.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentDelete**
> commentDelete(commentId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String commentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.commentDelete(commentId);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->commentDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentLike**
> CommentLiked commentLike(commentId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String commentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.commentLike(commentId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->commentLike: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **String**|  | 

### Return type

[**CommentLiked**](CommentLiked.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentUnlike**
> commentUnlike(commentId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String commentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.commentUnlike(commentId);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->commentUnlike: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **comments**
> CommentPage comments(postId, cursor, parent)



GET: a page of comments (or one comment's replies). POST: a new one. Signed-in readers also see their own held comments and which they liked, so their answers are private; everyone else's may be kept 15 s.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String cursor = cursor_example; // String | 
final String parent = parent_example; // String | 

try {
    final response = api.comments(postId, cursor, parent);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->comments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **parent** | **String**|  | [optional] 

### Return type

[**CommentPage**](CommentPage.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **engagementState**
> Map<String, PostState> engagementState(posts)



Counts and this reader's marks for up to 50 posts: `?posts=id,id`. Guests get the counts alone.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String posts = posts_example; // String | Comma-separated post ids, at most 50

try {
    final response = api.engagementState(posts);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->engagementState: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **posts** | **String**| Comma-separated post ids, at most 50 | 

### Return type

[**Map&lt;String, PostState&gt;**](PostState.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **follow**
> Following follow(kind, target)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String kind = kind_example; // String | 
final String target = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.follow(kind, target);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->follow: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 
 **target** | **String**|  | 

### Return type

[**Following**](Following.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **like**
> Liked like(postId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.like(postId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->like: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 

### Return type

[**Liked**](Liked.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **opened**
> PostState opened(postId, openedRequest)



A story was opened: counted (views, readers) and its counts given back. Guests too.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final OpenedRequest openedRequest = ; // OpenedRequest | 

try {
    final response = api.opened(postId, openedRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->opened: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 
 **openedRequest** | [**OpenedRequest**](OpenedRequest.md)|  | [optional] 

### Return type

[**PostState**](PostState.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readers**
> Readers readers(postId, cursor)



Who read the story: signed-in readers who did not choose to be left out, and how many guests.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String cursor = cursor_example; // String | 

try {
    final response = api.readers(postId, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->readers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 
 **cursor** | **String**|  | [optional] 

### Return type

[**Readers**](Readers.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unbookmark**
> unbookmark(postId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unbookmark(postId);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->unbookmark: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unfollow**
> unfollow(kind, target)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String kind = kind_example; // String | 
final String target = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unfollow(kind, target);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->unfollow: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 
 **target** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unlike**
> unlike(postId)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getEngagementApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unlike(postId);
} on DioException catch (e) {
    print('Exception when calling EngagementApi->unlike: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

