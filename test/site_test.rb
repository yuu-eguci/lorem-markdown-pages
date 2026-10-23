# frozen_string_literal: true

require "digest"
require "test_helper"

class SiteTest < Minitest::Test
  include SiteFiles

  CSP = "default-src 'none'; script-src 'self'; style-src 'self'; " \
        "img-src 'self' https://user-images.githubusercontent.com; font-src 'self'; " \
        "base-uri 'none'; form-action 'none'"

  def test_pages_declare_the_content_security_policy_before_loading_resources
    PAGES.each do |page|
      head = html(page).at("head").element_children
      csp = head.index { |node| node["http-equiv"] == "Content-Security-Policy" }

      refute_nil(csp, page)
      assert_equal(CSP, head[csp]["content"], page)
      assert_operator(csp, :<, head.index { |node| %w[link script].include?(node.name) }, page)
    end
  end

  def test_pages_use_leap_day_theme
    PAGES.each do |page|
      stylesheets = html(page).css("link[rel=stylesheet]").map { |link| link["href"] }

      assert(stylesheets.any? { |href| href.start_with?("#{BASEURL}/assets/css/style.css") }, page)
    end
  end

  def test_site_local_urls_resolve
    PAGES.each do |page|
      html(page).css("a[href], link[href], script[src], img[src]").each do |node|
        url = node["href"] || node["src"]
        next unless url.start_with?("#{BASEURL}/")

        assert(published?(url), "#{page}: #{url}")
      end
    end
  end

  def test_images_have_alt_text_and_sources_allowed_by_the_policy
    PAGES.each do |page|
      html(page).css("img").each do |img|
        refute_empty(img["alt"].to_s, "#{page}: #{img["src"]}")
        assert(allowed?("img-src", img["src"]), "#{page}: #{img["src"]}")
      end
    end
  end

  def test_scripts_are_same_origin_even_inside_comments
    PAGES.each do |page|
      File.read(File.join(SITE, page)).scan(/<script\b[^>]*\ssrc=["']([^"']+)["']/i).flatten.each do |src|
        assert(src.start_with?("#{BASEURL}/"), "#{page}: #{src}")
      end
    end
  end

  def test_jquery_matches_the_official_release
    digest = Digest::SHA256.file(File.join(SITE, "assets/js/jquery-3.7.1.min.js")).base64digest

    assert_equal("/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=", digest)
  end

  def test_jquery_is_not_vulnerable
    PAGES.each do |page|
      html(page).css("script[src*='jquery']").each do |script|
        version = script["src"][/jquery-(\d+\.\d+\.\d+)/, 1]

        assert_operator(Gem::Version.new(version), :>=, Gem::Version.new("3.5.0"), "#{page}: #{script["src"]}")
      end
    end
  end

  def test_development_files_are_not_published
    published = Dir.children(SITE)
    development_files = %w[Dockerfile compose.yaml Gemfile Gemfile.lock Rakefile test]

    assert_empty(published & development_files)
  end

  def test_markdown_sources_are_not_published
    assert_empty(Dir.glob("**/*.md", base: SITE))
  end

  def test_pages_declare_their_language
    { "index.html" => "en-US", "document1.html" => "en-US", "document2.html" => "ja-JP" }.each do |page, lang|
      assert_equal(lang, html(page).at("html")["lang"], page)
      assert_equal(lang.tr("-", "_"), html(page).at("meta[property='og:locale']")["content"], page)
    end
  end

  def test_viewport_allows_zoom
    PAGES.each do |page|
      assert_equal("width=device-width, initial-scale=1", html(page).at("meta[name=viewport]")["content"], page)
    end
  end

  private

  def allowed?(directive, url)
    sources = CSP.split("; ").find { |rule| rule.start_with?("#{directive} ") }.split.drop(1)
    sources.any? { |source| url.start_with?(source == "'self'" ? "#{BASEURL}/" : "#{source}/") }
  end

  def published?(url)
    path = File.join(SITE, url.delete_prefix(BASEURL).sub(/[?#].*/, ""))
    [path, "#{path}.html", File.join(path, "index.html")].any? { |candidate| File.file?(candidate) }
  end
end
