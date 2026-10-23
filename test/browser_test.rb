# frozen_string_literal: true

require "open3"
require "test_helper"
require "webrick"

class BrowserTest < Minitest::Test
  include SiteFiles

  HEADINGS = "section h1, section h2, section h3"
  SERVER = WEBrick::HTTPServer.new(BindAddress: "127.0.0.1", Port: 0,
                                   Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
  SERVER.mount(BASEURL, WEBrick::HTTPServlet::FileHandler, SITE)
  Thread.new { SERVER.start }
  Minitest.after_run { SERVER.shutdown }

  def test_heading_ids_generated_by_kramdown_are_kept
    PAGES.each do |page|
      assert_equal(ids(html(page).css(HEADINGS)), ids(rendered(page).css(HEADINGS)), page)
    end
  end

  def test_nav_links_point_to_distinct_headings
    PAGES.each do |page|
      links = rendered(page).css("nav a").map { |link| [link.text, link["href"]] }
      hrefs = links.map(&:last)

      assert_equal(hrefs.uniq, hrefs, page)
      assert_equal(rendered(page).css(HEADINGS).map { |heading| [heading.text, "##{heading["id"]}"] }, links, page)
    end
  end

  private

  def ids(nodes)
    nodes.map { |node| node["id"] }
  end

  def rendered(page)
    @rendered ||= {}
    @rendered[page] ||= begin
      url = "http://127.0.0.1:#{SERVER.config[:Port]}#{BASEURL}/#{page}"
      dom, status = Open3.capture2("chromium-headless-shell", "--no-sandbox", "--virtual-time-budget=10000",
                                   "--dump-dom", url, err: File::NULL)
      assert(status.success?, url)
      Nokogiri::HTML(dom)
    end
  end
end
