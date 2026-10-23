lorem-markdown-pages
===

## Description

This repository tries to decorate Markdown documents using GitHub Pages, themes.

## Fancy badges(shields.io)

<img alt="issues" src="https://img.shields.io/github/issues/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="forks" src="https://img.shields.io/github/forks/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="stars" src="https://img.shields.io/github/stars/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="license" src="https://img.shields.io/github/license/yuu-eguci/lorem-markdown-pages?style=for-the-badge">

<img alt="Markdown" src="https://img.shields.io/badge/-Markdown-000000.svg?logo=markdown&style=for-the-badge"> <img alt="Ruby" src="https://img.shields.io/badge/-Ruby-CC342D.svg?logo=ruby&style=for-the-badge"> <img alt="Docker" src="https://img.shields.io/badge/-Docker-2496ED.svg?logo=docker&style=for-the-badge"> <img alt="GitHub" src="https://img.shields.io/badge/-Github-181717.svg?logo=github&style=for-the-badge">

## 概要

- 公開先: <https://yuu-eguci.github.io/lorem-markdown-pages/> (GitHub Pages、`main` の `/` をビルド)
- Docker: 対応!
- ランタイム: Ruby 3.3.12 + github-pages 232 (Jekyll 3.10.0)。GitHub Pages のビルド環境に合わせてある
- ページ: front matter 付きの md がページになる (`index.md`・`document1.md`・`document2.md`)。生の md は公開しない。`README.md` はリポジトリ用なので除外
- 言語: ページの front matter に `lang` を書くと `<html lang>` と `og:locale` に反映される (日本語の `document2.md` は `ja-JP`)。省略時は `en-US`
- lint: RuboCop (Ruby) と mdl (Markdown)
- jQuery: 3.7.1 (MIT) を `assets/js/jquery-3.7.1.min.js` に同梱していて、外部 CDN は読まない。テストで公式リリースとハッシュが一致することを確認する
- CSP: `default-src 'none'` ベースの Content-Security-Policy を meta タグで付けている (script・style・font は同一オリジン、画像は同一オリジンと `user-images.githubusercontent.com` だけ)。GitHub Pages はレスポンスヘッダを設定できないので meta で、`frame-ancestors` みたいに meta では効かないものは入れていない
- テスト: Minitest。サイトをビルドして、リンク・画像・スクリプト・公開ファイル・言語指定・ズーム可否・CSP を確認する。見出しナビのリンクと CSP 違反がないことは headless Chromium で確認する (外部ネットワークを遮断した状態で動くことを確認)
- CI: GitHub Actions で Docker イメージをビルドして lint とテストを実行する

## パッと実行してみたい

```bash
# イメージをビルド
docker compose build

# ローカルでプレビュー (http://127.0.0.1:4000/lorem-markdown-pages/)
docker compose up

# lint とテスト
docker compose run --rm site bundle exec rake
```

`bundle exec rake lint` で lint だけ、`bundle exec rake test` でテストだけ実行できる。
