# news_api_client.api.SiteConfigApi

## Load the API package

```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to _http://localhost_

| Method                                        | HTTP request                | Description |
| --------------------------------------------- | --------------------------- | ----------- |
| [**siteConfig**](SiteConfigApi.md#siteconfig) | **GET** /api/v1/site-config |

# **siteConfig**

> SiteConfig siteConfig()

### Example

```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSiteConfigApi();

try {
    final response = api.siteConfig();
    print(response);
} on DioException catch (e) {
    print('Exception when calling SiteConfigApi->siteConfig: $e\n');
}
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SiteConfig**](SiteConfig.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
