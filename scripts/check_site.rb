#!/usr/bin/env ruby

require "nokogiri"
require "pathname"
require "json"
require "uri"
require "csv"

root = Pathname.new(File.expand_path("../docs", __dir__))
expected_poem_count = CSV.read(File.expand_path("../poems.csv", __dir__), headers: true).size
site_url = "https://akonkia.github.io/a-spiral-under-poetry-maya-oakes"
errors = []
html_files = root.glob("**/*.html")
canonical_urls = []

html_files.each do |file|
  document = Nokogiri::HTML(File.read(file))
  document.css("a[href], link[href], script[src], img[src]").each do |element|
    reference = element["href"] || element["src"]
    next if reference.nil? || reference.empty? || reference.start_with?("#", "mailto:", "http://", "https://")

    clean_reference = reference.split("#", 2).first.split("?", 2).first
    target = (file.dirname + clean_reference).cleanpath
    target = target + "index.html" if target.directory?
    errors << "#{file.relative_path_from(root)} -> #{reference}" unless target.exist?
  end

  relative_path = file.relative_path_from(root).to_s
  if relative_path == "404.html"
    robots = document.at_css('meta[name="robots"]')&.[]("content").to_s
    errors << "404.html must be noindex" unless robots.include?("noindex")
    next
  end

  canonical = document.css('link[rel="canonical"]')
  errors << "#{relative_path} must have one canonical URL" unless canonical.size == 1
  canonical_url = canonical.first&.[]("href")
  canonical_urls << canonical_url if canonical_url
  errors << "#{relative_path} has invalid canonical URL" unless canonical_url&.start_with?("#{site_url}/")

  open_graph_url = document.at_css('meta[property="og:url"]')&.[]("content")
  errors << "#{relative_path} Open Graph URL does not match canonical" unless open_graph_url == canonical_url

  json_ld = document.at_css('script[type="application/ld+json"]')&.text
  begin
    structured_data = JSON.parse(json_ld.to_s)
    errors << "#{relative_path} structured-data URL does not match canonical" unless structured_data["url"] == canonical_url
    if relative_path.start_with?("poems/")
      errors << "#{relative_path} is missing structured publication date" if structured_data["datePublished"].to_s.empty?
      errors << "#{relative_path} is missing structured poem topics" unless structured_data["keywords"].is_a?(Array) && structured_data["keywords"].any?
    end
  rescue JSON::ParserError
    errors << "#{relative_path} has invalid JSON-LD"
  end
end

sitemap = Nokogiri::XML(File.read(root + "sitemap.xml"))
sitemap.remove_namespaces!
sitemap_urls = sitemap.css("url loc").map(&:text)
errors << "sitemap URLs do not match canonical pages" unless sitemap_urls.sort == canonical_urls.sort
errors << "sitemap contains duplicate URLs" unless sitemap_urls.uniq.size == sitemap_urls.size

robots = File.read(root + "robots.txt")
errors << "robots.txt does not advertise sitemap" unless robots.include?("Sitemap: #{site_url}/sitemap.xml")

reader = Nokogiri::HTML(File.read(root + "read/index.html"))
poems = reader.css("[data-reader-poem]")
contents_links = reader.css("#contents .reader-toc-chapter li a")
tagged_reader_poems = poems.count { |poem| poem.css(".poem-tags a").any? }
page_numbers = poems.map { |poem| poem["data-page"] }
folios = reader.css(".reader-folio").map(&:text).map(&:strip)
errors << "reader contains #{poems.size} poems, expected #{expected_poem_count}" unless poems.size == expected_poem_count
errors << "duplicate reader poem anchors" unless poems.map { |poem| poem["id"] }.uniq.size == poems.size
errors << "contents contains #{contents_links.size} poems, expected #{expected_poem_count}" unless contents_links.size == expected_poem_count
errors << "only #{tagged_reader_poems} reader poems have tags" unless tagged_reader_poems == poems.size
errors << "reader page numbers are incomplete" unless page_numbers == (1..poems.size).map { |number| format("%02d", number) }
errors << "reader folios do not match page numbers" unless folios == page_numbers

if errors.any?
  warn errors.join("\n")
  exit 1
end

puts "Checked #{html_files.size} HTML files; all local links resolve."
puts "Continuous reader contains #{poems.size} uniquely anchored poems."
puts "Table of contents lists all #{contents_links.size} poems."
puts "All #{tagged_reader_poems} poems have linked topic tags."
puts "Reader folios run continuously from #{page_numbers.first} to #{page_numbers.last}."
puts "SEO metadata and sitemap cover #{canonical_urls.size} indexable pages."
