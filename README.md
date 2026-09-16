# A Spiral Under — poetry portfolio

A static GitHub Pages portfolio and continuous digital manuscript for Maya Oakes.

- `docs/index.html` is the portfolio and searchable poem index.
- `docs/read/index.html` is the uninterrupted book-reading experience with chapter openings, progress, and saved reading position.
- `docs/poems/` contains one permanent page per poem.
- `content/poems/` contains the clean source text for all poems.
- `chapter-map.csv` controls manuscript order and chapter placement.
- `poem-tags.csv` preserves the complete tag archive recovered from the original Substack posts.
- `curated-topics.csv` provides the smaller, consistent topic vocabulary shown on the site.
- `assets/booklet/` contains chapter motifs extracted from Maya's earlier printed booklet and adapted for the web layout.
- `assets/poems/` contains the original poem illustrations recovered from that booklet.
- `docs/sitemap.xml` and `docs/robots.txt` are generated with the site, alongside canonical, social, and structured metadata on every page.

## Build

Run:

```sh
ruby scripts/build_site.rb
ruby scripts/check_site.rb
```

The generator rebuilds the publishable `docs/` directory without a framework or package installation. To change a poem, edit its file in `content/poems/`; to reorder or reclassify poems, edit `chapter-map.csv`.

## Publish with GitHub Pages

1. Create a GitHub repository and place this folder at its root.
2. Push the files to the repository's `main` branch.
3. In **Settings → Pages**, choose **Deploy from a branch**.
4. Select `main` and the `/docs` folder, then save.

GitHub will provide the public site address after the first deployment.

## Copyright

Copyright © 2025-2026 Maya Oakes. All rights reserved. See `LICENSE`.

## Inventory

Confirmed poems: **47**

- **38** poems published as Substack posts
- **8** unique poems published as standalone Substack Notes
- **1** poem published as a Substack reply
- **1** additional Substack post is the table of contents and is not counted as a poem

`poems.csv` contains one row per poem and a stable page slug. It is ready to drive a one-poem-per-page GitHub Pages site.

## Notes audit

The public profile page visually showed only three recent Notes, but its complete public activity feed contains 143 items. After separating original Notes from replies, restacks, shares, and announcements, 96 original Notes remained. Eight contain clear, unique poems.

A separate audit of all 173 entries in the public Replies feed recovered one short poem:

- “The Felling of the Good Tree,” published March 20, 2026. Its title refers to Shajareh Tayyebeh—the “Good Tree”—the name of the school bombed in Minab, Iran.

Several poems were also published in Notes before or alongside their post versions. They are counted once as works rather than twice as publications:

- “Overflow”
- “Yearning”
- “Aivolved”
- the refrain later incorporated into “Blackberry bush”

“Scroll to another reel” was posted twice as two Notes on the same day and is counted once.

The author reviewed all nine ambiguous microtexts, aphorisms, captions, and lyrical replies and confirmed that none are poems. `review-candidates.csv` is therefore empty apart from its header.

## Naming notes

- “October ReadMe” is the Substack post title; the poem heading in the post is “October Readme.”
- “Autumn Prelude” is the published post title; the table of contents calls it “Autumn Interlude.”
- “Map lI: Road That Only Goes Out” appears to contain a lowercase `l` in the published title; the inventory normalizes it to “Map II: Road That Only Goes Out.”
