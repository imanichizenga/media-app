# news_api_client.model.Article

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
**authors** | [**List&lt;PublicByline&gt;**](PublicByline.md) |  | 
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
**body** | **Map&lt;String, Object?&gt;** |  | 
**assets** | [**Map&lt;String, Map&lt;String, Object?&gt;&gt;**](Map.md) |  | 
**links** | [**Map&lt;String, RelatedTarget&gt;**](RelatedTarget.md) |  | 
**breadcrumbs** | [**List&lt;PublicCategory&gt;**](PublicCategory.md) |  | 
**tags** | [**List&lt;PublicLabel&gt;**](PublicLabel.md) |  | 
**regions** | [**List&lt;PublicRegion&gt;**](PublicRegion.md) |  | 
**story** | [**PublicStoryRef**](PublicStoryRef.md) |  | 
**engagement** | [**PublicPolicy**](PublicPolicy.md) |  | 
**contentWarning** | **String** |  | 
**sourceUrl** | **String** |  | 
**updateNote** | **String** |  | 
**correctionNote** | **String** |  | 
**seo** | [**PublicSeo**](PublicSeo.md) |  | 
**firstPublishedAt** | [**DateTime**](DateTime.md) |  | 
**liveEndedAt** | [**DateTime**](DateTime.md) |  | 
**locked** | **bool** | Only the opening of the body is here; the rest is for subscribers (see subscriptions) | [optional] 
**translations** | [**List&lt;Translation&gt;**](Translation.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


