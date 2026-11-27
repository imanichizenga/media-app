from django.conf import settings
from django.urls import path, re_path

from newsplatform.accounts import reader_api as readers
from newsplatform.common import health
from newsplatform.content import public_api as content
from newsplatform.engagement import api as engage
from newsplatform.media import dev
from newsplatform.pages import public_api as pages
from newsplatform.seo import public_api as seo
from newsplatform.site_config import brand_api as brand
from newsplatform.site_config.api import AppConfigView, PublicConfigView, well_known

API = "api/v1/"
CONTENT = API + "content/"  # one prefix, so one CDN purge covers it
urlpatterns = [
    path("theme/current.css", brand.current_css),
    re_path(r"^theme/(?P<digest>[0-9a-f]{16})\.css$", brand.theme_css),
    re_path(
        r"^theme/logo/(?P<kind>wordmark|symbol)-(?P<digest>[0-9a-f]{32})/(?P<name>[a-z0-9-]{1,18}\.(?:svg|png))$",
        brand.logo_file,
    ),
    re_path(r"^theme/manifest-(?P<locale>sw|en)\.webmanifest$", brand.manifest),
    path("health/live", health.live),
    path("health/ready", health.ready),
    path(API + "site-config", PublicConfigView.as_view()),
    path(API + "app-config", AppConfigView.as_view()),
    re_path(r"^\.well-known/(?P<name>assetlinks\.json|apple-app-site-association)$", well_known),
    path(CONTENT + "home", content.HomeView.as_view()),
    path(CONTENT + "latest", content.LatestView.as_view()),
    path(CONTENT + "types/<slug:kind>", content.TypeView.as_view()),
    path(CONTENT + "categories/<slug:slug>", content.CategoryFeedView.as_view()),
    path(CONTENT + "tags/<slug:slug>", content.TagFeedView.as_view()),
    path(CONTENT + "stories/<slug:slug>", content.StoryFeedView.as_view()),
    path(CONTENT + "authors/<slug:slug>", content.AuthorFeedView.as_view()),
    path(CONTENT + "articles/<slug:slug>", content.ArticleView.as_view()),
    path(CONTENT + "articles/<slug:slug>/related", content.RelatedView.as_view()),
    path(CONTENT + "navigation", content.NavigationView.as_view()),
    path(CONTENT + "search", content.SearchView.as_view()),
    path(CONTENT + "search/suggest", content.SuggestView.as_view()),
    path(CONTENT + "pages", pages.PublicPageListView.as_view()),
    path(CONTENT + "pages/<slug:key>", pages.PublicPageView.as_view()),
    path(CONTENT + "sitemap", seo.SitemapIndexView.as_view()),
    path(CONTENT + "sitemap/news", seo.SitemapNewsView.as_view()),
    path(CONTENT + "sitemap/<slug:month>", seo.SitemapMonthView.as_view()),
    path(CONTENT + "resolve", content.ResolveView.as_view()),
    # Readers (ADR-0050): never cached, except what is the same for everyone.
    path(API + "auth/methods", readers.MethodsView.as_view()),
    path(API + "auth/code", readers.CodeRequestView.as_view()),
    path(API + "auth/code/verify", readers.CodeVerifyView.as_view()),
    path(API + "auth/google", readers.GoogleView.as_view()),
    path(API + "auth/apple", readers.AppleView.as_view()),
    path(API + "auth/refresh", readers.RefreshView.as_view()),
    path(API + "auth/sign-out", readers.SignOutView.as_view()),
    path(API + "me", readers.MeView.as_view()),
    path(API + "me/export", readers.ExportView.as_view()),
    path(API + "me/<slug:what>", engage.MyListView.as_view()),
    path(API + "engagement/state", engage.StateView.as_view()),
    path(API + "engagement/posts/<uuid:post_id>/like", engage.LikeView.as_view()),
    path(API + "engagement/posts/<uuid:post_id>/bookmark", engage.BookmarkView.as_view()),
    path(API + "engagement/posts/<uuid:post_id>/comments", engage.CommentsView.as_view()),
    path(API + "engagement/posts/<uuid:post_id>/opened", engage.OpenedView.as_view()),
    path(API + "engagement/posts/<uuid:post_id>/readers", engage.ReadersView.as_view()),
    path(API + "engagement/comments/<uuid:comment_id>", engage.CommentView.as_view()),
    path(API + "engagement/comments/<uuid:comment_id>/like", engage.CommentLikeView.as_view()),
    path(API + "engagement/follows/<slug:kind>/<uuid:target>", engage.FollowView.as_view()),
]
if settings.STORAGE_ENDPOINT_URL:
    urlpatterns.append(path("media/<path:path>", dev.serve))
