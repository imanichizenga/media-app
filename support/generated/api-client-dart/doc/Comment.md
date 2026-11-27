# news_api_client.model.Comment

## Load the model package
```dart
import 'package:news_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**body** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**author** | [**CommentAuthor**](CommentAuthor.md) |  | 
**likeCount** | **int** |  | 
**replyCount** | **int** |  | 
**liked** | **bool** |  | 
**mine** | **bool** |  | 
**pinned** | **bool** |  | 
**held** | **bool** | Waiting for a moderator; only its writer sees it. | 
**parent** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


