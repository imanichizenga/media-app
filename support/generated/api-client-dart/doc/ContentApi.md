# news_api_client.api.ContentApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**article**](ContentApi.md#article) | **GET** /api/v1/content/articles/{slug} | 
[**author**](ContentApi.md#author) | **GET** /api/v1/content/authors/{slug} | 
[**byType**](ContentApi.md#bytype) | **GET** /api/v1/content/types/{kind} | 
[**category**](ContentApi.md#category) | **GET** /api/v1/content/categories/{slug} | 
[**home**](ContentApi.md#home) | **GET** /api/v1/content/home | 
[**latest**](ContentApi.md#latest) | **GET** /api/v1/content/latest | 
[**navigation**](ContentApi.md#navigation) | **GET** /api/v1/content/navigation | 
[**page**](ContentApi.md#page) | **GET** /api/v1/content/pages/{key} | 
[**pages**](ContentApi.md#pages) | **GET** /api/v1/content/pages | 
[**related**](ContentApi.md#related) | **GET** /api/v1/content/articles/{slug}/related | 
[**resolve**](ContentApi.md#resolve) | **GET** /api/v1/content/resolve | 
[**search**](ContentApi.md#search) | **GET** /api/v1/content/search | 
[**sitemapIndex**](ContentApi.md#sitemapindex) | **GET** /api/v1/content/sitemap | 
[**sitemapMonth**](ContentApi.md#sitemapmonth) | **GET** /api/v1/content/sitemap/{month} | 
[**sitemapNews**](ContentApi.md#sitemapnews) | **GET** /api/v1/content/sitemap/news | 
[**story**](ContentApi.md#story) | **GET** /api/v1/content/stories/{slug} | 
[**tag**](ContentApi.md#tag) | **GET** /api/v1/content/tags/{slug} | 


# **article**
> Article article(slug, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.article(slug, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->article: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**Article**](Article.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **author**
> AuthorPage author(slug, cursor, limit, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.author(slug, cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->author: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**AuthorPage**](AuthorPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **byType**
> FeedPage byType(kind, cursor, limit, locale)



Video list, shorts, galleries, opinion…

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String kind = kind_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.byType(kind, cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->byType: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**FeedPage**](FeedPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **category**
> CategoryPage category(slug, cursor, limit, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.category(slug, cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->category: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**CategoryPage**](CategoryPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **home**
> Home home(locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String locale = locale_example; // String | 

try {
    final response = api.home(locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->home: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**Home**](Home.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **latest**
> FeedPage latest(cursor, limit, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.latest(cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->latest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**FeedPage**](FeedPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **navigation**
> List<NavigationItem> navigation(locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String locale = locale_example; // String | 

try {
    final response = api.navigation(locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->navigation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**List&lt;NavigationItem&gt;**](NavigationItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **page**
> PublicPage page(key, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String key = key_example; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.page(key, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->page: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **key** | **String**|  | 
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**PublicPage**](PublicPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pages**
> PublicPages pages(locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String locale = locale_example; // String | 

try {
    final response = api.pages(locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->pages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**PublicPages**](PublicPages.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **related**
> Related related(slug, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.related(slug, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->related: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**Related**](Related.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resolve**
> Resolve resolve(path)



Where an old address lives now. The website asks before it answers 404.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String path = path_example; // String | 

try {
    final response = api.resolve(path);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->resolve: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **String**|  | 

### Return type

[**Resolve**](Resolve.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **search**
> Search search(locale, q)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String locale = locale_example; // String | 
final String q = q_example; // String | 

try {
    final response = api.search(locale, q);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->search: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] [default to 'sw']
 **q** | **String**|  | [optional] 

### Return type

[**Search**](Search.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sitemapIndex**
> SitemapIndex sitemapIndex()



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();

try {
    final response = api.sitemapIndex();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->sitemapIndex: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SitemapIndex**](SitemapIndex.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sitemapMonth**
> SitemapEntries sitemapMonth(month)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String month = month_example; // String | 

try {
    final response = api.sitemapMonth(month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->sitemapMonth: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **month** | **String**|  | 

### Return type

[**SitemapEntries**](SitemapEntries.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sitemapNews**
> SitemapEntries sitemapNews()



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();

try {
    final response = api.sitemapNews();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->sitemapNews: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SitemapEntries**](SitemapEntries.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **story**
> StoryPage story(slug, cursor, limit, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.story(slug, cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->story: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**StoryPage**](StoryPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tag**
> TagPage tag(slug, cursor, limit, locale)



GET only, no cookies, no user. Anything about a person is a separate endpoint (M4).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getContentApi();
final String slug = slug_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String locale = locale_example; // String | 

try {
    final response = api.tag(slug, cursor, limit, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->tag: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **locale** | **String**|  | [optional] [default to 'sw']

### Return type

[**TagPage**](TagPage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

