# news_api_client.api.SubscriptionsApi

## Load the API package
```dart
import 'package:news_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**subscriptionCheckout**](SubscriptionsApi.md#subscriptioncheckout) | **POST** /api/v1/subscriptions/checkout | 
[**subscriptionMine**](SubscriptionsApi.md#subscriptionmine) | **GET** /api/v1/subscriptions/mine | 
[**subscriptionPayment**](SubscriptionsApi.md#subscriptionpayment) | **GET** /api/v1/subscriptions/payments/{payment_id} | 
[**subscriptionPlans**](SubscriptionsApi.md#subscriptionplans) | **GET** /api/v1/subscriptions/plans | 
[**subscriptionStory**](SubscriptionsApi.md#subscriptionstory) | **GET** /api/v1/subscriptions/posts/{post_id} | 


# **subscriptionCheckout**
> Payment subscriptionCheckout(checkoutRequest)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSubscriptionsApi();
final CheckoutRequest checkoutRequest = ; // CheckoutRequest | 

try {
    final response = api.subscriptionCheckout(checkoutRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SubscriptionsApi->subscriptionCheckout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **checkoutRequest** | [**CheckoutRequest**](CheckoutRequest.md)|  | 

### Return type

[**Payment**](Payment.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionMine**
> MySubscription subscriptionMine(locale)



### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSubscriptionsApi();
final String locale = locale_example; // String | 

try {
    final response = api.subscriptionMine(locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SubscriptionsApi->subscriptionMine: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] 

### Return type

[**MySubscription**](MySubscription.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionPayment**
> Payment subscriptionPayment(paymentId, locale)



Where a payment is, for the reader watching it. Asks Snippe now and then, in case its word is late.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSubscriptionsApi();
final String paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.subscriptionPayment(paymentId, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SubscriptionsApi->subscriptionPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentId** | **String**|  | 
 **locale** | **String**|  | [optional] 

### Return type

[**Payment**](Payment.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionPlans**
> Offer subscriptionPlans(locale)



What a reader may buy. The same for everyone.

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSubscriptionsApi();
final String locale = locale_example; // String | 

try {
    final response = api.subscriptionPlans(locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SubscriptionsApi->subscriptionPlans: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **locale** | **String**|  | [optional] 

### Return type

[**Offer**](Offer.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionStory**
> Article subscriptionStory(postId, locale)



The whole of a story for subscribers, for a reader with paid time left (402 otherwise).

### Example
```dart
import 'package:news_api_client/api.dart';

final api = NewsApiClient().getSubscriptionsApi();
final String postId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String locale = locale_example; // String | 

try {
    final response = api.subscriptionStory(postId, locale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SubscriptionsApi->subscriptionStory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**|  | 
 **locale** | **String**|  | [optional] 

### Return type

[**Article**](Article.md)

### Authorization

[readerBearer](../README.md#readerBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

