#!/usr/bin/env ruby

require "cgi"
require "csv"
require "fileutils"
require "json"

ROOT = File.expand_path("..", __dir__)
OUTPUT = File.join(ROOT, "docs")
CONTENT = File.join(ROOT, "content", "poems")

SECTIONS = {
  "Prologue" => {
    slug: "prologue",
    label: "Opening",
    persona: "Before the seasons",
    artwork: "branch",
    description: "A seed touches ground. Plans scatter. The spiral begins."
  },
  "Spring" => {
    slug: "spring",
    label: "Spring",
    persona: "The Biologist",
    artwork: "biologist",
    description: "The living self in close observation: bodies and bonds, desire and illness, inherited wounds, and the instincts that carry us toward survival."
  },
  "Summer" => {
    slug: "summer",
    label: "Summer",
    persona: "The Silent Cartographer",
    artwork: "cartographer",
    description: "A quiet witness records atrocities, erased places, displaced lives, and what others learn not to see."
  },
  "Autumn" => {
    slug: "autumn",
    label: "Autumn",
    persona: "The Philosopher",
    artwork: "philosopher",
    description: "A season of questions: choice, identity, consciousness, memory, meaning, and the shape of a life."
  },
  "Winter" => {
    slug: "winter",
    label: "Winter",
    persona: "The Ethnographer",
    artwork: "ethnographer",
    description: "Near the fire, stories preserve folklore, ritual, shared memory, and what one generation carries into another."
  },
  "Loose Leaves" => {
    slug: "loose-leaves",
    label: "Loose Leaves",
    persona: "Small forms & fragments",
    title: "Loose Leaves",
    artwork: "spiral",
    description: "Brief pieces that sit outside the four voices while remaining part of the spiral."
  }
}.freeze

def escape(value)
  CGI.escapeHTML(value.to_s)
end

def section_heading(section)
  section[:title] || section[:persona]
end

def section_overline(section)
  section[:title] ? section[:persona] : section[:label]
end

def relative_prefix(depth)
  "../" * depth
end

def page_shell(title:, description:, body:, depth:, section: nil, extra_class: nil)
  prefix = relative_prefix(depth)
  section_class = section ? " theme-#{SECTIONS.fetch(section)[:slug]}" : ""
  classes = ["site", section_class, extra_class].compact.join(" ")

  <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="description" content="#{escape(description)}">
      <meta name="theme-color" content="#ffffff">
      <title>#{escape(title)} · A Spiral Under</title>
      <link rel="icon" href="#{prefix}assets/logo.png" type="image/png">
      <link rel="stylesheet" href="#{prefix}assets/styles.css">
      <script defer src="#{prefix}assets/site.js"></script>
    </head>
    <body class="#{classes.strip}">
      <a class="skip-link" href="#content">Skip to content</a>
      <header class="site-header">
        <a class="brand" href="#{prefix}index.html" aria-label="A Spiral Under, home">
          <img src="#{prefix}assets/logo.png" alt="" width="40" height="40">
          <span>A Spiral Under</span>
        </a>
        <nav aria-label="Primary navigation">
          <a href="#{prefix}read/index.html">Read</a>
          <a href="#{prefix}read/index.html#contents">Contents</a>
          <a href="#{prefix}topics/index.html">Topics</a>
          <a href="#{prefix}about/index.html">About</a>
          <button class="text-button" type="button" data-random-poem>Random poem</button>
        </nav>
      </header>
      <main id="content">
        #{body}
      </main>
      <footer class="site-footer">
        <p>© 2025-2026 Maya Oakes. All rights reserved.</p>
        <p><a href="https://dervendaur.substack.com/">Originally published at A Spiral Under on Substack</a></p>
      </footer>
    </body>
    </html>
  HTML
end

def write_page(path, content)
  destination = File.join(OUTPUT, path)
  FileUtils.mkdir_p(File.dirname(destination))
  File.write(destination, content)
end

def poem_text(slug)
  path = File.join(CONTENT, "#{slug}.txt")
  raise "Missing poem source: #{path}" unless File.exist?(path)

  File.read(path).strip
end

def poem_lines(text)
  text.split("\n", -1).map do |line|
    line.empty? ? "<span class=\"poem-break\" aria-hidden=\"true\"></span>" : escape(line)
  end.join("\n")
end

def tag_links(tags, prefix:)
  return "" if tags.empty?

  links = tags.map do |tag|
    "<a href=\"#{prefix}topics/#{escape(tag["tag_slug"])}/index.html\">#{escape(tag["tag"])}</a>"
  end.join
  "<div class=\"poem-tags\" aria-label=\"Topics\">#{links}</div>"
end

inventory = CSV.read(File.join(ROOT, "poems.csv"), headers: true).each_with_object({}) do |row, rows|
  rows[row["slug"]] = row.to_h
end

curated_topics = CSV.read(File.join(ROOT, "curated-topics.csv"), headers: true).map(&:to_h)
tags_by_poem = curated_topics.group_by { |row| row["slug"] }
tags_by_poem.transform_values! do |rows|
  rows.uniq { |row| row["tag_slug"] }.sort_by { |row| row["tag"].downcase }
end

map = CSV.read(File.join(ROOT, "chapter-map.csv"), headers: true).map(&:to_h)
map.each do |entry|
  source = inventory.fetch(entry["slug"])
  entry.merge!(source)
  entry["position"] = entry["position"].to_i
  entry["tags"] = tags_by_poem.fetch(entry["slug"], [])
end

map.sort_by! { |entry| [SECTIONS.keys.index(entry["section"]), entry["position"]] }
map.each_with_index do |entry, index|
  entry["global_position"] = index
  entry["previous"] = map[index - 1] if index.positive?
  entry["next"] = map[index + 1]
end

topics = map.each_with_object({}) do |entry, index|
  entry["tags"].each do |tag|
    topic = index[tag["tag_slug"]] ||= { "tag" => tag["tag"], "tag_slug" => tag["tag_slug"], "poems" => [] }
    topic["poems"] << entry
  end
end.values.sort_by { |topic| topic["tag"].downcase }

poem_links_json = JSON.generate(map.map { |entry| "poems/#{entry["slug"]}/index.html" })

asset_dir = File.join(OUTPUT, "assets")
FileUtils.mkdir_p(asset_dir)
FileUtils.cp(File.join(ROOT, "assets", "logo.png"), File.join(asset_dir, "logo.png"))
FileUtils.cp(File.join(ROOT, "assets", "styles.css"), File.join(asset_dir, "styles.css"))
FileUtils.rm_rf(File.join(asset_dir, "booklet"))
FileUtils.cp_r(File.join(ROOT, "assets", "booklet"), File.join(asset_dir, "booklet"))
site_js = File.read(File.join(ROOT, "assets", "site.js")).sub("__POEM_LINKS__", poem_links_json)
File.write(File.join(asset_dir, "site.js"), site_js)
File.write(File.join(OUTPUT, ".nojekyll"), "")

chapter_cards = SECTIONS.reject { |name, _| name == "Prologue" }.map do |name, section|
  first_entry = map.find { |entry| entry["section"] == name }
  start_page = first_entry["global_position"] + 1
  <<~HTML
    <a class="season-card season-#{section[:slug]}" href="chapters/#{section[:slug]}/index.html">
      <img class="season-art" src="assets/booklet/#{section[:artwork]}.webp" alt="" loading="lazy">
      <span class="season-number"><small>p.</small> #{format("%02d", start_page)}</span>
      <span class="season-label">#{escape(section_overline(section))}</span>
      <strong>#{escape(section_heading(section))}</strong>
      <span>#{escape(section[:description])}</span>
    </a>
  HTML
end.join

all_poems = map.map do |entry|
  persona = entry["persona"].to_s.empty? ? SECTIONS.fetch(entry["section"])[:persona] : entry["persona"]
  <<~HTML
    <li data-poem-item data-section="#{escape(entry["section"].downcase)}" data-search="#{escape(entry["title"].downcase)}">
      <a href="poems/#{entry["slug"]}/index.html">
        <span>#{escape(entry["title"])}</span>
        <small>#{escape(entry["section"])} · #{escape(persona)}</small>
      </a>
    </li>
  HTML
end.join

home_body = <<~HTML
  <section class="hero">
    <div class="hero-copy">
      <p class="eyebrow">A poetry collection by Maya Oakes</p>
      <h1>A Spiral<br><em>Under</em></h1>
      <p class="hero-intro">Poems of life, memory, loss, and the quiet science of being human.</p>
      <div class="hero-actions">
        <a class="primary-button" href="read/index.html">Read the book</a>
        <a class="resume-link" href="read/index.html" data-resume-reading hidden>Continue reading</a>
        <a class="secondary-link" href="#all-poems">Browse all #{map.size} poems</a>
      </div>
    </div>
    <div class="spiral-mark" aria-hidden="true">
      <img src="assets/booklet/spiral.webp" alt="">
    </div>
  </section>
  <section class="season-grid" id="seasons" aria-label="Poetry chapters">
    #{chapter_cards}
  </section>
  <section class="poem-index" id="all-poems">
    <div class="index-heading">
      <div>
        <p class="eyebrow">Complete index</p>
        <h2>All poems</h2>
      </div>
      <label class="search-field">
        <span>Find a poem</span>
        <input type="search" placeholder="Search by title" data-poem-search>
      </label>
    </div>
    <ul class="poem-list" data-poem-list>
      #{all_poems}
    </ul>
    <p class="empty-state" data-empty-state hidden>No poem matches that title.</p>
  </section>
HTML

home = page_shell(
  title: "Poems",
  description: "A Spiral Under, a seasonal poetry portfolio by Maya Oakes.",
  body: home_body,
  depth: 0,
  extra_class: "home-page"
)
write_page("index.html", home)

FileUtils.rm_rf(File.join(OUTPUT, "topics"))

topic_links = topics.map do |topic|
  count = topic["poems"].size
  <<~HTML
    <li>
      <a href="#{topic["tag_slug"]}/index.html">
        <span>#{escape(topic["tag"])}</span>
        <small>#{count} #{count == 1 ? "poem" : "poems"}</small>
      </a>
    </li>
  HTML
end.join

topics_body = <<~HTML
  <header class="topic-hero">
    <p class="eyebrow">Ways through the collection</p>
    <h1>Topics</h1>
    <p>Follow a subject across seasons, voices, and forms.</p>
  </header>
  <ul class="topic-cloud">
    #{topic_links}
  </ul>
HTML

write_page(
  "topics/index.html",
  page_shell(
    title: "Topics",
    description: "Browse the poems in A Spiral Under by topic.",
    body: topics_body,
    depth: 1,
    extra_class: "topics-page"
  )
)

topics.each do |topic|
  poems = topic["poems"].map do |entry|
    <<~HTML
      <li>
        <a href="../../poems/#{entry["slug"]}/index.html">
          <span>#{escape(entry["title"])}</span>
          <small>#{escape(entry["section"])} · p. #{format("%02d", entry["global_position"] + 1)}</small>
        </a>
      </li>
    HTML
  end.join

  body = <<~HTML
    <header class="topic-hero">
      <a class="chapter-kicker" href="../index.html">All topics</a>
      <h1>#{escape(topic["tag"])}</h1>
      <p>#{topic["poems"].size} #{topic["poems"].size == 1 ? "poem" : "poems"} in this collection.</p>
    </header>
    <ul class="poem-list topic-poem-list">#{poems}</ul>
  HTML

  write_page(
    "topics/#{topic["tag_slug"]}/index.html",
    page_shell(
      title: topic["tag"],
      description: "Poems about #{topic["tag"]} in A Spiral Under.",
      body: body,
      depth: 2,
      extra_class: "topic-page"
    )
  )
end

reader_contents = SECTIONS.map do |name, section|
  entries = map.select { |entry| entry["section"] == name }.sort_by { |entry| entry["position"] }
  next if entries.empty?

  poems = entries.map do |entry|
    <<~HTML
      <article class="reader-poem" id="#{entry["slug"]}" data-reader-poem data-title="#{escape(entry["title"])}">
        <p class="reader-position">#{format("%02d", entry["global_position"] + 1)} / #{format("%02d", map.size)}</p>
        <h2>#{escape(entry["title"])}</h2>
        <div class="poem-text">#{poem_lines(poem_text(entry["slug"]))}</div>
        #{tag_links(entry["tags"], prefix: "../")}
        <a class="reader-permalink" href="../poems/#{entry["slug"]}/index.html">Permanent page</a>
      </article>
    HTML
  end.join

  <<~HTML
    <section class="reader-chapter theme-#{section[:slug]}" aria-labelledby="reader-#{section[:slug]}">
      <header class="reader-chapter-opening">
        <img class="chapter-art" src="../assets/booklet/#{section[:artwork]}.webp" alt="">
        <p class="eyebrow">#{escape(section_overline(section))}</p>
        <h1 id="reader-#{section[:slug]}">#{escape(section_heading(section))}</h1>
        <p>#{escape(section[:description])}</p>
      </header>
      #{poems}
    </section>
  HTML
end.compact.join

reader_toc = SECTIONS.map do |name, section|
  entries = map.select { |entry| entry["section"] == name }.sort_by { |entry| entry["position"] }
  next if entries.empty?

  titles = entries.map do |entry|
    <<~HTML
      <li>
        <a href="##{entry["slug"]}">
          <span>#{format("%02d", entry["global_position"] + 1)}</span>
          #{escape(entry["title"])}
        </a>
      </li>
    HTML
  end.join

  <<~HTML
    <section class="reader-toc-chapter">
      <header>
        <p>#{escape(section_overline(section))}</p>
        <h2>#{escape(section_heading(section))}</h2>
      </header>
      <ol>#{titles}</ol>
    </section>
  HTML
end.compact.join

reader_body = <<~HTML
  <div class="reading-progress" aria-hidden="true"><span data-reading-progress></span></div>
  <header class="reader-cover">
    <p class="eyebrow">A poetry manuscript</p>
    <h1>A Spiral <em>Under</em></h1>
    <p>By Maya Oakes</p>
    <a class="primary-button" href="#prologue">Open the book</a>
  </header>
  <nav class="reader-contents" id="contents" aria-label="Table of contents">
    <p class="eyebrow">Contents</p>
    <h2>Table of contents</h2>
    #{reader_toc}
  </nav>
  <div class="reader-manuscript">
    #{reader_contents}
  </div>
  <aside class="reader-status" aria-live="polite">
    <span data-reader-current>Cover</span>
    <span data-reader-percent>0%</span>
  </aside>
HTML

write_page(
  "read/index.html",
  page_shell(
    title: "Read the book",
    description: "Read A Spiral Under as a continuous seasonal poetry manuscript.",
    body: reader_body,
    depth: 1,
    extra_class: "book-reader"
  )
)

SECTIONS.each do |name, section|
  entries = map.select { |entry| entry["section"] == name }.sort_by { |entry| entry["position"] }
  next if entries.empty?

  list = entries.map do |entry|
    excerpt = poem_text(entry["slug"]).lines.find { |line| !line.strip.empty? }.to_s.strip
    <<~HTML
      <li>
        <a href="../../poems/#{entry["slug"]}/index.html">
          <span class="chapter-position">#{format("%02d", entry["position"])}</span>
          <span class="chapter-title">#{escape(entry["title"])}</span>
          <span class="chapter-excerpt">#{escape(excerpt)}</span>
        </a>
      </li>
    HTML
  end.join

  body = <<~HTML
    <header class="chapter-hero">
      <img class="chapter-art" src="../../assets/booklet/#{section[:artwork]}.webp" alt="">
      <p class="eyebrow">#{escape(section_overline(section))} · #{entries.size} #{entries.size == 1 ? "poem" : "poems"}</p>
      <h1>#{escape(section_heading(section))}</h1>
      <p>#{escape(section[:description])}</p>
    </header>
    <ol class="chapter-list">
      #{list}
    </ol>
    <nav class="chapter-cycle" aria-label="Chapters">
      #{SECTIONS.reject { |section_name, _| section_name == "Prologue" }.map { |section_name, item| "<a#{section_name == name ? " aria-current=\"page\"" : ""} href=\"../#{item[:slug]}/index.html\">#{escape(section_heading(item))}</a>" }.join}
    </nav>
  HTML

  write_page(
    "chapters/#{section[:slug]}/index.html",
    page_shell(
      title: section[:title] ? "#{section[:title]} — #{section[:persona]}" : "#{section[:label]} — #{section[:persona]}",
      description: section[:description],
      body: body,
      depth: 2,
      section: name,
      extra_class: "chapter-page"
    )
  )
end

map.each do |entry|
  section = SECTIONS.fetch(entry["section"])
  previous_link = if entry["previous"]
    "<a class=\"previous\" href=\"../#{entry["previous"]["slug"]}/index.html\"><span>Previous</span>#{escape(entry["previous"]["title"])}</a>"
  else
    "<span></span>"
  end
  next_link = if entry["next"]
    transition = entry["next"]["section"] == entry["section"] ? "Next" : "Next chapter · #{entry["next"]["section"]}"
    "<a class=\"next\" href=\"../#{entry["next"]["slug"]}/index.html\"><span>#{escape(transition)}</span>#{escape(entry["next"]["title"])}</a>"
  else
    "<a class=\"next\" href=\"../../index.html\"><span>Return</span>All poems</a>"
  end

  body = <<~HTML
    <article class="poem-page">
      <header class="poem-header">
        <a class="chapter-kicker" href="../../chapters/#{section[:slug]}/index.html">#{escape(section[:label])} · #{escape(section[:persona])}</a>
        <h1>#{escape(entry["title"])}</h1>
      </header>
      <div class="poem-text" aria-label="Poem text">#{poem_lines(poem_text(entry["slug"]))}</div>
      #{tag_links(entry["tags"], prefix: "../../")}
      <footer class="poem-source">
        <a href="#{escape(entry["source_url"])}">View the original publication ↗</a>
      </footer>
    </article>
    <nav class="poem-navigation" aria-label="Poem navigation">
      #{previous_link}
      #{next_link}
    </nav>
  HTML

  write_page(
    "poems/#{entry["slug"]}/index.html",
    page_shell(
      title: entry["title"],
      description: "#{entry["title"]}, a poem by Maya Oakes.",
      body: body,
      depth: 2,
      section: entry["section"],
      extra_class: "reading-page"
    )
  )
end

about_body = <<~HTML
  <article class="about-page">
    <p class="eyebrow">About the book</p>
    <h1>Four seasons.<br>Four witnesses.</h1>
    <div class="about-copy">
      <p><strong>A Spiral Under</strong> is a poetry collection by Maya Oakes, a scientist with a creative artist’s past and a renewed practice of writing poetry.</p>
      <p>The Biologist reads life from within. The Silent Cartographer records atrocities. The Philosopher asks what experience means. The Ethnographer keeps stories alive near the winter fire.</p>
      <p>The poems first appeared on Substack between 2025 and 2026. This portfolio gathers them into the seasonal manuscript they were always moving toward.</p>
    </div>
    <a class="primary-button" href="../poems/prologue/index.html">Read from the beginning</a>
  </article>
HTML

write_page(
  "about/index.html",
  page_shell(
    title: "About",
    description: "About A Spiral Under and poet Maya Oakes.",
    body: about_body,
    depth: 1,
    extra_class: "about-shell"
  )
)

write_page("404.html", page_shell(
  title: "Page not found",
  description: "This page could not be found.",
  depth: 0,
  body: <<~HTML
    <section class="not-found">
      <p class="eyebrow">404</p>
      <h1>The path has faded.</h1>
      <p>The map ends here, but the poems continue.</p>
      <a class="primary-button" href="index.html">Return to the collection</a>
    </section>
  HTML
))

puts "Built #{map.size} poem pages and #{SECTIONS.size} section pages in #{OUTPUT}"
