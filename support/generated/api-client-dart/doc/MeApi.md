# news_api_client.api.MeApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**me**](MeApi.md#me) | **GET** /api/v1/me | 
[**meDelete**](MeApi.md#medelete) | **DELETE** /api/v1/me | 
[**meExport**](MeApi.md#meexport) | **GET** /api/v1/me/export | 
[**meUpdate**](MeApi.md#meupdate) | **PATCH** /api/v1/me | 
[**myList**](MeApi.md#mylist) | **GET** /api/v1/me/{what} | 


# **me**
> Reader me()



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getMeApi();

try {
    final response = api.me();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->me: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Reader**](Reader.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meDelete**
> Deletion meDelete()



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getMeApi();

try {
    final response = api.meDelete();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meDelete: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Deletion**](Deletion.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meExport**
> ModelExport meExport()



Everything kept about the reader, as JSON (PDPA Tanzania 2022).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getMeApi();

try {
    final response = api.meExport();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meExport: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ModelExport**](ModelExport.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meUpdate**
> Reader meUpdate(patchedProfileRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getMeApi();
final PatchedProfileRequest patchedProfileRequest = ; // PatchedProfileRequest | 

try {
    final response = api.meUpdate(patchedProfileRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **patchedProfileRequest** | [**PatchedProfileRequest**](PatchedProfileRequest.md)|  | [optional] 

### Return type

[**Reader**](Reader.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **myList**
> CardList myList(what, locale)



`what`: saved, liked (cards) or follows (FollowList).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getMeApi();
final String what = what_example; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.myList(what, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->myList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **what** | **String**|  | 
 **locale** | **String**|  | [optional] 

### Return type

[**CardList**](CardList.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

