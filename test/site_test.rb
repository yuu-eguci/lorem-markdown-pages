# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "nokogiri"
require "tmpdir"

class SiteTest < Minitest::Test
  BASEURL = "/lorem-markdown-pages"
  PAGES = %w[index.html document1.html document2.html].freeze
  SITE = Dir.mktmpdir("lorem-markdown-pages-site")

  system("bundle", "exec", "jekyll", "build", "--quiet", "--destination", SITE, exception: true)
  Minitest.after_run { FileUtils.remove_entry(SITE) }

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

  private

  def html(page)
    Nokogiri::HTML(File.read(File.join(SITE, page)))
  end

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
