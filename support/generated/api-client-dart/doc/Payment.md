# news_api_client.model.Payment

## Load the model package
```dart
import 'package:news_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | [**PaymentStatusEnum**](PaymentStatusEnum.md) |  | 
**method** | [**PaymentMethodEnum**](PaymentMethodEnum.md) |  | 
**amount** | **int** |  | 
**currency** | **String** |  | 
**plan** | **String** |  | 
**checkoutUrl** | **String** | Cards: send the reader here | 
**completedAt** | [**DateTime**](DateTime.md) |  | 
**subscription** | [**MySubscription**](MySubscription.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


