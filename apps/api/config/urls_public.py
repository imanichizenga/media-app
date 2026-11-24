from django.conf import settings
from django.urls import path

from newsplatform.common import health
from newsplatform.content import public_api as content
from newsplatform.media import dev
from newsplatform.site_config.api import PublicConfigView

API = "api/v1/"
CONTENT = API + "content/"  # one prefix, so one CDN purge covers it
urlpatterns = [
    path("health/live", health.live),
    path("health/ready", health.ready),
    path(API + "site-config", PublicConfigView.as_view()),
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
    path(CONTENT + "resolve", content.ResolveView.as_view()),
]
if settings.STORAGE_ENDPOINT_URL:
    urlpatterns.append(path("media/<path:path>", dev.serve))
