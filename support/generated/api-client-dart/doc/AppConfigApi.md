# news_api_client.api.AppConfigApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**appConfig**](AppConfigApi.md#appconfig) | **GET** /api/v1/app-config | 


# **appConfig**
> AppConfig appConfig()



For installed apps. ETag and a short life: a kill switch must arrive within minutes.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getAppConfigApi();

try {
    final response = api.appConfig();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AppConfigApi->appConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AppConfig**](AppConfig.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

