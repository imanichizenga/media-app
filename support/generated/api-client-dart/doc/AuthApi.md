# news_api_client.api.AuthApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authApple**](AuthApi.md#authapple) | **POST** /api/v1/auth/apple | 
[**authCode**](AuthApi.md#authcode) | **POST** /api/v1/auth/code | 
[**authCodeVerify**](AuthApi.md#authcodeverify) | **POST** /api/v1/auth/code/verify | 
[**authGoogle**](AuthApi.md#authgoogle) | **POST** /api/v1/auth/google | 
[**authMethods**](AuthApi.md#authmethods) | **GET** /api/v1/auth/methods | 
[**authRefresh**](AuthApi.md#authrefresh) | **POST** /api/v1/auth/refresh | 
[**authSignOut**](AuthApi.md#authsignout) | **POST** /api/v1/auth/sign-out | 


# **authApple**
> SignedIn authApple(providerSignInRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final ProviderSignInRequest providerSignInRequest = ; // ProviderSignInRequest | 

try {
    final response = api.authApple(providerSignInRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authApple: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **providerSignInRequest** | [**ProviderSignInRequest**](ProviderSignInRequest.md)|  | [optional] 

### Return type

[**SignedIn**](SignedIn.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authCode**
> CodeSent authCode(codeRequestRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final CodeRequestRequest codeRequestRequest = ; // CodeRequestRequest | 

try {
    final response = api.authCode(codeRequestRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **codeRequestRequest** | [**CodeRequestRequest**](CodeRequestRequest.md)|  | 

### Return type

[**CodeSent**](CodeSent.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authCodeVerify**
> SignedIn authCodeVerify(codeVerifyRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final CodeVerifyRequest codeVerifyRequest = ; // CodeVerifyRequest | 

try {
    final response = api.authCodeVerify(codeVerifyRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authCodeVerify: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **codeVerifyRequest** | [**CodeVerifyRequest**](CodeVerifyRequest.md)|  | 

### Return type

[**SignedIn**](SignedIn.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authGoogle**
> SignedIn authGoogle(providerSignInRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final ProviderSignInRequest providerSignInRequest = ; // ProviderSignInRequest | 

try {
    final response = api.authGoogle(providerSignInRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **providerSignInRequest** | [**ProviderSignInRequest**](ProviderSignInRequest.md)|  | [optional] 

### Return type

[**SignedIn**](SignedIn.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authMethods**
> Methods authMethods()



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();

try {
    final response = api.authMethods();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authMethods: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Methods**](Methods.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRefresh**
> SignedIn authRefresh(refreshRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final RefreshRequest refreshRequest = ; // RefreshRequest | 

try {
    final response = api.authRefresh(refreshRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authRefresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

[**SignedIn**](SignedIn.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSignOut**
> authSignOut(refreshRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAuthApi();
final RefreshRequest refreshRequest = ; // RefreshRequest | 

try {
    api.authSignOut(refreshRequest);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authSignOut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

