lorem-markdown-pages
===

## Description

This repository tries to decorate Markdown documents using GitHub Pages, themes.

## Fancy badges(shields.io)

<img alt="issues" src="https://img.shields.io/github/issues/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="forks" src="https://img.shields.io/github/forks/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="stars" src="https://img.shields.io/github/stars/yuu-eguci/lorem-markdown-pages?style=for-the-badge"> <img alt="license" src="https://img.shields.io/github/license/yuu-eguci/lorem-markdown-pages?style=for-the-badge">

<img alt="Markdown" src="https://img.shields.io/badge/-Markdown-000000.svg?logo=markdown&style=for-the-badge"> <img alt="Ruby" src="https://img.shields.io/badge/-Ruby-CC342D.svg?logo=ruby&style=for-the-badge"> <img alt="TypeScript" src="https://img.shields.io/badge/-TypeScript-3178C6.svg?logo=typescript&style=for-the-badge"> <img alt="Docker" src="https://img.shields.io/badge/-Docker-2496ED.svg?logo=docker&style=for-the-badge"> <img alt="GitHub" src="https://img.shields.io/badge/-Github-181717.svg?logo=github&style=for-the-badge">

## 概要

- 公開先: <https://yuu-eguci.github.io/lorem-markdown-pages/> (GitHub Pages、`main` の `/` をビルド)
- Docker: 対応!
- ランタイム: Ruby 3.3.14 + github-pages 232 (Jekyll 3.10.0)。GitHub Pages のビルド環境 (Ruby 3.3 系・github-pages 232) に合わせてある。Bundler は 4.1.0
- TypeScript: 自前の JS は `assets/js/main.ts` (strict) に書き、 TypeScript 7.0 の `tsc` で公開用の `assets/js/main.js` を生成してコミットする。GitHub Pages の legacy build は TypeScript をコンパイルできないため。 `main.ts`・ `package.json` などは公開しない。Node.js 26 (LTS) と npm 12 は Docker イメージの中だけで使う
- ページ: front matter 付きの md がページになる (`index.md`・`document1.md`・`document2.md`)。生の md は公開しない。`README.md` はリポジトリ用なので除外
- 言語: ページの front matter に `lang` を書くと `<html lang>` と `og:locale` に反映される (日本語の `document2.md` は `ja-JP`)。省略時は `en-US`
- 画像: サンプル画像は Markdown の属性 (`{: width="1432" height="574"}`) で実寸を書いていて、読み込み中もレイアウトがずれない。テーマの `section img { max-width: 100% }` に `height: auto` を足す CSS (`assets/css/style.scss`) で、縮小しても比率が崩れない
- lint: RuboCop (Ruby) と mdl (Markdown)
- jQuery: 4.1.0 (MIT) を `assets/js/jquery-4.1.0.min.js` に同梱していて、外部 CDN は読まない。テストで公式リリースとハッシュが一致することを確認する
- 対応ブラウザ: モダンブラウザだけ。IE 向けの html5shiv (外部 CDN) と `X-UA-Compatible` は外してあるので、HTML に外部スクリプトの参照はコメント内も含めて無い
- CSP: `default-src 'none'` ベースの Content-Security-Policy を meta タグで付けている (script・style・font は同一オリジン、画像は同一オリジンと `user-images.githubusercontent.com` だけ)。GitHub Pages はレスポンスヘッダを設定できないので meta で、`frame-ancestors` みたいに meta では効かないものは入れていない
- テスト: Minitest と `node:test` (TypeScript)。サイトをビルドして、リンク・画像 (alt と寸法)・スクリプト・公開ファイル・言語指定・ズーム可否・CSP を確認する。見出しナビのリンクと CSP 違反がないことは headless Chromium で確認する (外部ネットワークを遮断した状態で動くことを確認)。ナビのリンクをクリックしたときに、その見出しまでスクロールしてリンクが active になることは `test/navigation.test.ts` で headless Chromium を操作して確認する。`main.ts` の型チェックと、コミットした `main.js` が `main.ts` から生成したものと一致することも確認する。workflow の action が SHA 固定で permissions が読み取りだけなことも確認する
- CI: GitHub Actions (`ubuntu-26.04`) で Docker イメージをビルドして lint・型チェック・テストを実行する。ビルドは `compose.yaml` を bake の定義として使い、BuildKit のレイヤーキャッシュを GitHub Actions のキャッシュに保存する (Gemfile.lock・ package-lock.json・ Dockerfile が変わらなければ 2 回目以降は数秒)。action は全部コミット SHA で固定、permissions は `contents: read` だけ

## パッと実行してみたい

```bash
# イメージをビルド
docker compose build

# ローカルでプレビュー (http://127.0.0.1:4000/lorem-markdown-pages/)
docker compose up

# lint・型チェック・テスト
docker compose run --rm site bundle exec rake

# assets/js/main.ts を編集したら main.js を生成し直す (assets/js だけ書き込み可能でマウントする)
docker compose run --rm --volume ./assets/js:/srv/site/assets/js site tsc
```

`bundle exec rake lint` で lint だけ、`bundle exec rake typecheck` で型チェックだけ、`bundle exec rake test` で Minitest だけ、`bundle exec rake test_ts` で TypeScript のテストだけ実行できる。
