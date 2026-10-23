# frozen_string_literal: true

require "test_helper"

class SiteTest < Minitest::Test
  include SiteFiles

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

  def test_images_have_alt_text_and_https_source
    PAGES.each do |page|
      html(page).css("img").each do |img|
        refute_empty(img["alt"].to_s, "#{page}: #{img["src"]}")
        assert(img["src"].start_with?("https://", "#{BASEURL}/"), "#{page}: #{img["src"]}")
      end
    end
  end

  def test_external_scripts_use_https_and_subresource_integrity
    external_scripts.each do |page, script|
      message = "#{page}: #{script["src"]}"

      assert(script["src"].start_with?("https://"), message)
      assert(script["integrity"].to_s.start_with?("sha"), message)
      assert_equal("anonymous", script["crossorigin"], message)
    end
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

  def external_scripts
    PAGES.flat_map do |page|
      html(page).css("script[src]")
                .reject { |script| script["src"].start_with?("#{BASEURL}/") }
                .map { |script| [page, script] }
    end
  end

  def published?(url)
    path = File.join(SITE, url.delete_prefix(BASEURL).sub(/[?#].*/, ""))
    [path, "#{path}.html", File.join(path, "index.html")].any? { |candidate| File.file?(candidate) }
  end
end
