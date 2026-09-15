#!/usr/bin/env ruby

require "csv"
require "fileutils"
require "json"
require "nokogiri"

ROOT = File.expand_path("..", __dir__)
AUDIT_TEXT_DIR = "/private/tmp/dervendaur-poem-texts"
AUDIT_PAGE_DIR = "/private/tmp/dervendaur-poem-pages"
PROFILE_GLOB = "/private/tmp/dervendaur-profile-feed-*.json"
REPLIES_GLOB = "/private/tmp/dervendaur-replies-*.json"
CONTENT_DIR = File.join(ROOT, "content", "poems")

NOTE_IDS = {
  "thoughts-keep-on-buzzing" => 198_452_885,
  "work-slips" => 200_361_321,
  "scroll-to-another-reel" => 202_485_317,
  "the-felling-of-the-good-tree" => 230_548_011,
  "the-heirs" => 227_680_296,
  "legacy" => 234_798_606,
  "birth-below-earth-roots-grow-slow" => 334_275_737,
  "silence-is-the-smallest-poem" => 334_259_822
}.freeze

IMAGE_POEMS = {
  "breathe-in-the-colours" => <<~POEM.strip
    Breathe in
    the colours

    See the music
    drift softly

    Roses learn
    to sing
  POEM
}.freeze

TRAILING_MARKERS = /\A(?:Image (?:source|credits)|Source:|Thanks for reading|Subscribe\z|Previous\z)/i

def normalize(text)
  text
    .gsub("\r", "")
    .gsub(/[ \t]+\n/, "\n")
    .gsub(/\n{3,}/, "\n\n")
    .strip
end

def preformatted_poem(slug)
  page = File.join(AUDIT_PAGE_DIR, "#{slug}.html")
  return nil unless File.exist?(page)

  document = Nokogiri::HTML(File.read(page))
  blocks = document.css(".body.markup pre")
  return nil if blocks.empty?

  normalize(blocks.max_by { |block| block.text.length }.text)
end

def cleaned_post_text(slug)
  preformatted = preformatted_poem(slug)
  return preformatted if preformatted

  path = File.join(AUDIT_TEXT_DIR, "#{slug}.txt")
  raise "Missing audited poem text: #{path}" unless File.exist?(path)

  lines = File.readlines(path, chomp: true)

  title_index = lines.index do |line|
    line.strip.downcase == slug.tr("-", " ").downcase
  end
  lines = lines[(title_index + 1)..] if title_index

  marker_index = lines.index { |line| line.strip.match?(TRAILING_MARKERS) }
  lines = lines[0...marker_index] if marker_index
  normalize(lines.join("\n"))
end

def comments_by_id
  files = Dir[PROFILE_GLOB] + Dir[REPLIES_GLOB]
  files.each_with_object({}) do |path, comments|
    JSON.parse(File.read(path)).fetch("items", []).each do |item|
      comment = item["comment"]
      comments[comment["id"]] = comment["body"] if comment
    end
  end
end

def cleaned_comment_text(slug, text)
  body = normalize(text.to_s)
  return body unless slug == "the-felling-of-the-good-tree"

  poem = body.split("The Felling of the Good Tree", 2).last.to_s.strip
  normalize("The Felling of the Good Tree\n\n#{poem}")
end

FileUtils.mkdir_p(CONTENT_DIR)
comments = comments_by_id
inventory = CSV.read(File.join(ROOT, "poems.csv"), headers: true)

inventory.each do |row|
  slug = row["slug"]
  text = if row["source_type"] == "post"
    cleaned_post_text(slug)
  elsif IMAGE_POEMS.key?(slug)
    IMAGE_POEMS.fetch(slug)
  else
    comment_id = NOTE_IDS.fetch(slug)
    cleaned_comment_text(slug, comments.fetch(comment_id))
  end

  lines = text.lines(chomp: true)
  first_content_index = lines.index { |line| !line.strip.empty? }
  if first_content_index && lines[first_content_index].strip.casecmp?(row["title"].strip)
    lines.delete_at(first_content_index)
    lines.delete_at(first_content_index) while lines[first_content_index]&.strip&.empty?
    text = normalize(lines.join("\n"))
  end

  File.write(File.join(CONTENT_DIR, "#{slug}.txt"), "#{text}\n")
end

puts "Imported #{inventory.size} poem texts into #{CONTENT_DIR}"
