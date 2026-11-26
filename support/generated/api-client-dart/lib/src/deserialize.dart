import 'package:news_api_client/src/model/app_config.dart';
import 'package:news_api_client/src/model/app_flags.dart';
import 'package:news_api_client/src/model/app_links.dart';
import 'package:news_api_client/src/model/app_localization.dart';
import 'package:news_api_client/src/model/app_maintenance.dart';
import 'package:news_api_client/src/model/app_pinning.dart';
import 'package:news_api_client/src/model/app_platform_versions.dart';
import 'package:news_api_client/src/model/app_versions.dart';
import 'package:news_api_client/src/model/article.dart';
import 'package:news_api_client/src/model/author_page.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:news_api_client/src/model/card_byline.dart';
import 'package:news_api_client/src/model/category_page.dart';
import 'package:news_api_client/src/model/category_translation.dart';
import 'package:news_api_client/src/model/feed_page.dart';
import 'package:news_api_client/src/model/home.dart';
import 'package:news_api_client/src/model/home_section.dart';
import 'package:news_api_client/src/model/logo.dart';
import 'package:news_api_client/src/model/navigation_item.dart';
import 'package:news_api_client/src/model/public_author.dart';
import 'package:news_api_client/src/model/public_byline.dart';
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/public_category_detail.dart';
import 'package:news_api_client/src/model/public_image.dart';
import 'package:news_api_client/src/model/public_label.dart';
import 'package:news_api_client/src/model/public_policy.dart';
import 'package:news_api_client/src/model/public_region.dart';
import 'package:news_api_client/src/model/public_seo.dart';
import 'package:news_api_client/src/model/public_story.dart';
import 'package:news_api_client/src/model/public_story_ref.dart';
import 'package:news_api_client/src/model/public_video.dart';
import 'package:news_api_client/src/model/related.dart';
import 'package:news_api_client/src/model/related_target.dart';
import 'package:news_api_client/src/model/resolve.dart';
import 'package:news_api_client/src/model/schemes.dart';
import 'package:news_api_client/src/model/search.dart';
import 'package:news_api_client/src/model/site_config.dart';
import 'package:news_api_client/src/model/site_identity.dart';
import 'package:news_api_client/src/model/site_localization.dart';
import 'package:news_api_client/src/model/site_theme.dart';
import 'package:news_api_client/src/model/site_theme_tokens.dart';
import 'package:news_api_client/src/model/story_page.dart';
import 'package:news_api_client/src/model/tag_page.dart';
import 'package:news_api_client/src/model/translation.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType,
    {bool growable = true}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AppConfig':
      return AppConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppFlags':
      return AppFlags.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppLinks':
      return AppLinks.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppLocalization':
      return AppLocalization.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppMaintenance':
      return AppMaintenance.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppPinning':
      return AppPinning.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppPlatformVersions':
      return AppPlatformVersions.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppVersions':
      return AppVersions.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Article':
      return Article.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuthorPage':
      return AuthorPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Card':
      return Card.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CardByline':
      return CardByline.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryPage':
      return CategoryPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryTranslation':
      return CategoryTranslation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CommentsEnum':
    case 'DefaultLocaleEnum':
    case 'FeedPage':
      return FeedPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Home':
      return Home.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeSection':
      return HomeSection.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Logo':
      return Logo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'NavigationItem':
      return NavigationItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PostTypeEnum':
    case 'PublicAuthor':
      return PublicAuthor.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicByline':
      return PublicByline.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicCategory':
      return PublicCategory.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublicCategoryDetail':
      return PublicCategoryDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublicImage':
      return PublicImage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicImageKindEnum':
    case 'PublicLabel':
      return PublicLabel.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicPolicy':
      return PublicPolicy.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicRegion':
      return PublicRegion.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicSeo':
      return PublicSeo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicStory':
      return PublicStory.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicStoryRef':
      return PublicStoryRef.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublicVideo':
      return PublicVideo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicVideoKindEnum':
    case 'Related':
      return Related.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RelatedTarget':
      return RelatedTarget.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Resolve':
      return Resolve.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Schemes':
      return Schemes.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Search':
      return Search.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteConfig':
      return SiteConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteIdentity':
      return SiteIdentity.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteLocalization':
      return SiteLocalization.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SiteTheme':
      return SiteTheme.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteThemeTokens':
      return SiteThemeTokens.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StoryPage':
      return StoryPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TagPage':
      return TagPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ThemeKeyEnum':
    case 'Translation':
      return Translation.fromJson(value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toList(growable: growable) as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toSet() as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map((dynamic v) => deserialize<BaseType, BaseType>(
              v, targetType,
              growable: growable)),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
