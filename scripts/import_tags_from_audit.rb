#!/usr/bin/env ruby

require "csv"
require "json"

ROOT = File.expand_path("..", __dir__)
AUDIT_PAGE_DIR = "/private/tmp/dervendaur-poem-pages"
STRUCTURAL_TAG = /\A(?:poetry|prologue|chapter\s+\d+)\z/i

def preload_data(path)
  html = File.read(path)
  match = html.match(/window\._preloads\s*=\s*JSON\.parse\(("(?:\\.|[^"\\])*")\)/m)
  raise "Could not find Substack preload data in #{path}" unless match

  JSON.parse(JSON.parse(match[1]))
end

inventory = CSV.read(File.join(ROOT, "poems.csv"), headers: true)
rows = []

inventory.each do |poem|
  next unless poem["source_type"] == "post"

  page = File.join(AUDIT_PAGE_DIR, "#{poem["slug"]}.html")
  raise "Missing archived Substack page: #{page}" unless File.exist?(page)

  preload_data(page).dig("post", "postTags").to_a.each do |tag|
    rows << {
      "slug" => poem["slug"],
      "tag" => tag.fetch("name"),
      "tag_slug" => tag.fetch("slug"),
      "is_topic" => !tag.fetch("name").match?(STRUCTURAL_TAG)
    }
  end
end

CSV.open(File.join(ROOT, "poem-tags.csv"), "w", write_headers: true, headers: %w[slug tag tag_slug is_topic]) do |csv|
  rows.sort_by { |row| [row["slug"], row["tag"].downcase] }.each { |row| csv << row.values }
end

topic_rows = rows.select { |row| row["is_topic"] }
puts "Recovered #{rows.size} original tag assignments, including #{topic_rows.size} topic assignments."
puts "Topic tags: #{topic_rows.map { |row| row["tag"] }.uniq.sort_by(&:downcase).join(", ")}"
