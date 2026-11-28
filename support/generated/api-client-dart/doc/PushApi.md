# news_api_client.api.PushApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**pushKey**](PushApi.md#pushkey) | **GET** /api/v1/push/key | 
[**pushSubscribe**](PushApi.md#pushsubscribe) | **POST** /api/v1/push/subscriptions | 
[**pushUnsubscribe**](PushApi.md#pushunsubscribe) | **DELETE** /api/v1/push/subscriptions | 


# **pushKey**
> PushKey pushKey()



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getPushApi();

try {
    final response = api.pushKey();
    print(response);
} on DioException catch (e) {
    print('Exception when calling PushApi->pushKey: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PushKey**](PushKey.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pushSubscribe**
> pushSubscribe(pushSubscriptionRequest)



This browser wants to hear of new stories (or no longer does). Signed in or not.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getPushApi();
final PushSubscriptionRequest pushSubscriptionRequest = ; // PushSubscriptionRequest | 

try {
    api.pushSubscribe(pushSubscriptionRequest);
} on DioException catch (e) {
    print('Exception when calling PushApi->pushSubscribe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pushSubscriptionRequest** | [**PushSubscriptionRequest**](PushSubscriptionRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pushUnsubscribe**
> pushUnsubscribe()



This browser wants to hear of new stories (or no longer does). Signed in or not.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getPushApi();

try {
    api.pushUnsubscribe();
} on DioException catch (e) {
    print('Exception when calling PushApi->pushUnsubscribe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

