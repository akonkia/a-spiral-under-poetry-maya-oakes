#!/usr/bin/env ruby

require "nokogiri"
require "pathname"
require "uri"

root = Pathname.new(File.expand_path("../docs", __dir__))
errors = []
html_files = root.glob("**/*.html")

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
end

reader = Nokogiri::HTML(File.read(root + "read/index.html"))
poems = reader.css("[data-reader-poem]")
contents_links = reader.css("#contents .reader-toc-chapter li a")
tagged_reader_poems = poems.count { |poem| poem.css(".poem-tags a").any? }
page_numbers = poems.map { |poem| poem["data-page"] }
folios = reader.css(".reader-folio").map(&:text).map(&:strip)
errors << "reader contains #{poems.size} poems, expected 47" unless poems.size == 47
errors << "duplicate reader poem anchors" unless poems.map { |poem| poem["id"] }.uniq.size == poems.size
errors << "contents contains #{contents_links.size} poems, expected 47" unless contents_links.size == 47
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
