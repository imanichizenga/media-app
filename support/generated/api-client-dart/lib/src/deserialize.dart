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
import 'package:news_api_client/src/model/bookmarked.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:news_api_client/src/model/card_byline.dart';
import 'package:news_api_client/src/model/card_list.dart';
import 'package:news_api_client/src/model/category_page.dart';
import 'package:news_api_client/src/model/category_translation.dart';
import 'package:news_api_client/src/model/checkout_request.dart';
import 'package:news_api_client/src/model/code_request_request.dart';
import 'package:news_api_client/src/model/code_sent.dart';
import 'package:news_api_client/src/model/code_verify_request.dart';
import 'package:news_api_client/src/model/comment.dart';
import 'package:news_api_client/src/model/comment_author.dart';
import 'package:news_api_client/src/model/comment_liked.dart';
import 'package:news_api_client/src/model/comment_page.dart';
import 'package:news_api_client/src/model/deletion.dart';
import 'package:news_api_client/src/model/feed_page.dart';
import 'package:news_api_client/src/model/following.dart';
import 'package:news_api_client/src/model/home.dart';
import 'package:news_api_client/src/model/home_section.dart';
import 'package:news_api_client/src/model/liked.dart';
import 'package:news_api_client/src/model/logo.dart';
import 'package:news_api_client/src/model/methods.dart';
import 'package:news_api_client/src/model/model_export.dart';
import 'package:news_api_client/src/model/my_subscription.dart';
import 'package:news_api_client/src/model/navigation_item.dart';
import 'package:news_api_client/src/model/new_comment_request.dart';
import 'package:news_api_client/src/model/offer.dart';
import 'package:news_api_client/src/model/opened_request.dart';
import 'package:news_api_client/src/model/page_translation.dart';
import 'package:news_api_client/src/model/patched_profile_request.dart';
import 'package:news_api_client/src/model/payment.dart';
import 'package:news_api_client/src/model/plan.dart';
import 'package:news_api_client/src/model/post_state.dart';
import 'package:news_api_client/src/model/provider_sign_in_request.dart';
import 'package:news_api_client/src/model/public_author.dart';
import 'package:news_api_client/src/model/public_byline.dart';
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/public_category_detail.dart';
import 'package:news_api_client/src/model/public_image.dart';
import 'package:news_api_client/src/model/public_label.dart';
import 'package:news_api_client/src/model/public_page.dart';
import 'package:news_api_client/src/model/public_page_link.dart';
import 'package:news_api_client/src/model/public_pages.dart';
import 'package:news_api_client/src/model/public_policy.dart';
import 'package:news_api_client/src/model/public_region.dart';
import 'package:news_api_client/src/model/public_seo.dart';
import 'package:news_api_client/src/model/public_story.dart';
import 'package:news_api_client/src/model/public_story_ref.dart';
import 'package:news_api_client/src/model/public_video.dart';
import 'package:news_api_client/src/model/push_key.dart';
import 'package:news_api_client/src/model/push_keys_request.dart';
import 'package:news_api_client/src/model/push_subscription_request.dart';
import 'package:news_api_client/src/model/reader.dart';
import 'package:news_api_client/src/model/reader_entry.dart';
import 'package:news_api_client/src/model/readers.dart';
import 'package:news_api_client/src/model/refresh_request.dart';
import 'package:news_api_client/src/model/related.dart';
import 'package:news_api_client/src/model/related_target.dart';
import 'package:news_api_client/src/model/resolve.dart';
import 'package:news_api_client/src/model/schemes.dart';
import 'package:news_api_client/src/model/search.dart';
import 'package:news_api_client/src/model/search_hit.dart';
import 'package:news_api_client/src/model/segment.dart';
import 'package:news_api_client/src/model/signed_in.dart';
import 'package:news_api_client/src/model/site_apps.dart';
import 'package:news_api_client/src/model/site_config.dart';
import 'package:news_api_client/src/model/site_engagement.dart';
import 'package:news_api_client/src/model/site_identity.dart';
import 'package:news_api_client/src/model/site_localization.dart';
import 'package:news_api_client/src/model/site_seo.dart';
import 'package:news_api_client/src/model/site_theme.dart';
import 'package:news_api_client/src/model/site_theme_tokens.dart';
import 'package:news_api_client/src/model/sitemap_entries.dart';
import 'package:news_api_client/src/model/sitemap_entry.dart';
import 'package:news_api_client/src/model/sitemap_index.dart';
import 'package:news_api_client/src/model/sitemap_month.dart';
import 'package:news_api_client/src/model/sitemap_translation.dart';
import 'package:news_api_client/src/model/story_page.dart';
import 'package:news_api_client/src/model/suggest.dart';
import 'package:news_api_client/src/model/suggestion.dart';
import 'package:news_api_client/src/model/tag_page.dart';
import 'package:news_api_client/src/model/translation.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
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
    case 'Bookmarked':
      return Bookmarked.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Card':
      return Card.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CardByline':
      return CardByline.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CardList':
      return CardList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryPage':
      return CategoryPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryTranslation':
      return CategoryTranslation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckoutRequest':
      return CheckoutRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CodeRequestRequest':
      return CodeRequestRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CodeSent':
      return CodeSent.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CodeVerifyRequest':
      return CodeVerifyRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Comment':
      return Comment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CommentAuthor':
      return CommentAuthor.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CommentLiked':
      return CommentLiked.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CommentPage':
      return CommentPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CommentsEnum':
    case 'DefaultLocaleEnum':
    case 'Deletion':
      return Deletion.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'EngineEnum':
    case 'FeedPage':
      return FeedPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Following':
      return Following.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Home':
      return Home.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeSection':
      return HomeSection.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Liked':
      return Liked.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LocaleEnum':
    case 'Logo':
      return Logo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Methods':
      return Methods.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ModelExport':
      return ModelExport.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MySubscription':
      return MySubscription.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NavigationItem':
      return NavigationItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NewCommentRequest':
      return NewCommentRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Offer':
      return Offer.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OpenedRequest':
      return OpenedRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PageTranslation':
      return PageTranslation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PatchedProfileRequest':
      return PatchedProfileRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Payment':
      return Payment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PaymentMethodEnum':
    case 'PaymentStatusEnum':
    case 'Plan':
      return Plan.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PlanIntervalEnum':
    case 'PostState':
      return PostState.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PostTypeEnum':
    case 'ProviderSignInRequest':
      return ProviderSignInRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
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
    case 'PublicPage':
      return PublicPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PublicPageLink':
      return PublicPageLink.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublicPages':
      return PublicPages.fromJson(value as Map<String, dynamic>) as ReturnType;
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
    case 'PushKey':
      return PushKey.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PushKeysRequest':
      return PushKeysRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PushSubscriptionRequest':
      return PushSubscriptionRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Reader':
      return Reader.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReaderEntry':
      return ReaderEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReaderMethodsEnum':
    case 'Readers':
      return Readers.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RefreshRequest':
      return RefreshRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
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
    case 'SearchHit':
      return SearchHit.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Segment':
      return Segment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SignedIn':
      return SignedIn.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteApps':
      return SiteApps.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteConfig':
      return SiteConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteEngagement':
      return SiteEngagement.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SiteIdentity':
      return SiteIdentity.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteLocalization':
      return SiteLocalization.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SiteSeo':
      return SiteSeo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteTheme':
      return SiteTheme.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SiteThemeTokens':
      return SiteThemeTokens.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SitemapEntries':
      return SitemapEntries.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SitemapEntry':
      return SitemapEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SitemapIndex':
      return SitemapIndex.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SitemapMonth':
      return SitemapMonth.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SitemapTranslation':
      return SitemapTranslation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StoryPage':
      return StoryPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Suggest':
      return Suggest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Suggestion':
      return Suggestion.fromJson(value as Map<String, dynamic>) as ReturnType;
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
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map(
                (dynamic v) => deserialize<BaseType, BaseType>(
                  v,
                  targetType,
                  growable: growable,
                ),
              ),
            )
            as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
