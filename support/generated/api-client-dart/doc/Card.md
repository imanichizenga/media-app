# news_api_client.model.Card

## Load the model package
```dart
import 'package:news_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**type** | [**PostTypeEnum**](PostTypeEnum.md) |  | 
**locale** | **String** |  | 
**path** | **String** |  | 
**slug** | **String** |  | 
**headline** | **String** |  | 
**railTitle** | **String** | At most 24 characters, for the live rail | 
**standfirst** | **String** |  | 
**category** | [**PublicCategory**](PublicCategory.md) |  | 
**authors** | [**List&lt;CardByline&gt;**](CardByline.md) |  | 
**image** | [**PublicImage**](PublicImage.md) |  | 
**video** | [**PublicVideo**](PublicVideo.md) |  | 
**youtubeId** | **String** |  | 
**durationMs** | **int** | Of the video, wherever it lives | 
**readingMinutes** | **int** |  | 
**publishedAt** | [**DateTime**](DateTime.md) |  | 
**modifiedAt** | [**DateTime**](DateTime.md) |  | 
**isSensitive** | **bool** |  | 
**premium** | **bool** | For subscribers: the card and the opening are for everyone | [optional] 
**breakingUntil** | [**DateTime**](DateTime.md) |  | 
**isLive** | **bool** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


