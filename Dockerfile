FROM ruby:3.3.14-slim-trixie@sha256:c285f774b589eb8ded47aaa8ed83fc0d23cbebb10fb0dea71151e65aeace1853 AS base

ENV BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    JEKYLL_BUILD_REVISION=local \
    PAGES_REPO_NWO=yuu-eguci/lorem-markdown-pages
WORKDIR /srv/site
RUN gem update --system 4.1.0 --no-document \
    && gem uninstall --executables rubygems-update \
    && rm -rf /usr/local/bundle/cache

FROM base AS gems

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf /usr/local/bundle/cache

FROM base

RUN apt-get update \
    && apt-get install -y --no-install-recommends chromium-headless-shell \
    && rm -rf /var/lib/apt/lists/*
COPY --from=gems /usr/local/bundle /usr/local/bundle
RUN useradd --create-home --uid 1000 site
USER site

EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--destination", "/tmp/site", "--force_polling"]
