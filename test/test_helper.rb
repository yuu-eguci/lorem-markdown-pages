# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "nokogiri"
require "tmpdir"

BASEURL = "/lorem-markdown-pages"
PAGES = %w[index.html document1.html document2.html].freeze
SITE = Dir.mktmpdir("lorem-markdown-pages-site")

system("bundle", "exec", "jekyll", "build", "--quiet", "--destination", SITE, exception: true)
Minitest.after_run { FileUtils.remove_entry(SITE) }

module SiteFiles
  def html(page)
    Nokogiri::HTML(File.read(File.join(SITE, page)))
  end
end
