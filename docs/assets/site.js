const poemLinks = ["poems/prologue/index.html","poems/birth-below-earth-roots-grow-slow/index.html","poems/these-pets-of-mine/index.html","poems/thoughts-keep-on-buzzing/index.html","poems/blue-canary/index.html","poems/yearning/index.html","poems/the-gift/index.html","poems/betrayal/index.html","poems/the-other-shoe/index.html","poems/dark-lessons/index.html","poems/riding-the-pain/index.html","poems/water-skippers/index.html","poems/catching-salmon/index.html","poems/a-place/index.html","poems/blackberry-bush/index.html","poems/you-age-like-milk/index.html","poems/map-i-eulogy-to-unborn/index.html","poems/map-ii-road-that-only-goes-out/index.html","poems/map-iii-skirmish-on-the-border/index.html","poems/scroll-to-another-reel/index.html","poems/the-felling-of-the-good-tree/index.html","poems/when-the-sky-falls/index.html","poems/autumn-prelude/index.html","poems/paintbox/index.html","poems/blue-curtain/index.html","poems/october-readme/index.html","poems/overflow/index.html","poems/aivolved/index.html","poems/toil/index.html","poems/shame-is/index.html","poems/brittle/index.html","poems/fears-unlisted/index.html","poems/linocut/index.html","poems/a-song-of-home/index.html","poems/no-north/index.html","poems/a-spiral-under/index.html","poems/legacy/index.html","poems/coffee-shop/index.html","poems/koschei-and-the-prince/index.html","poems/farmer-and-the-one-eyed-likho/index.html","poems/leshy-and-the-hunter/index.html","poems/twelve-plates-on-christmas-eve/index.html","poems/love-in-the-c-and-d-key/index.html","poems/the-heirs/index.html","poems/breathe-in-the-colours/index.html","poems/work-slips/index.html","poems/silence-is-the-smallest-poem/index.html"];

document.querySelectorAll("[data-random-poem]").forEach((button) => {
  button.addEventListener("click", () => {
    const prefix = window.location.pathname.includes("/poems/") || window.location.pathname.includes("/chapters/")
      ? "../../"
      : window.location.pathname.includes("/about/")
        ? "../"
        : "";
    const choice = poemLinks[Math.floor(Math.random() * poemLinks.length)];
    window.location.href = `${prefix}${choice}`;
  });
});

const search = document.querySelector("[data-poem-search]");
if (search) {
  const items = [...document.querySelectorAll("[data-poem-item]")];
  const emptyState = document.querySelector("[data-empty-state]");

  search.addEventListener("input", () => {
    const query = search.value.trim().toLowerCase();
    let visible = 0;

    items.forEach((item) => {
      const matches = item.dataset.search.includes(query) || item.dataset.section.includes(query);
      item.hidden = !matches;
      visible += matches ? 1 : 0;
    });

    emptyState.hidden = visible !== 0;
  });
}

const readerPoems = [...document.querySelectorAll("[data-reader-poem]")];
const progressBar = document.querySelector("[data-reading-progress]");
const currentTitle = document.querySelector("[data-reader-current]");
const currentPercent = document.querySelector("[data-reader-percent]");

if (readerPoems.length) {
  const recordPosition = (poem) => {
    const index = readerPoems.indexOf(poem);
    const percent = Math.round(((index + 1) / readerPoems.length) * 100);
    const target = `#${poem.id}`;

    currentTitle.textContent = poem.dataset.title;
    currentPercent.textContent = `${percent}%`;
    progressBar.style.width = `${percent}%`;
    window.localStorage.setItem("spiral-reading-position", target);
    window.history.replaceState(null, "", target);
  };

  const observer = new IntersectionObserver((entries) => {
    entries
      .filter((entry) => entry.isIntersecting)
      .sort((first, second) => second.intersectionRatio - first.intersectionRatio)
      .slice(0, 1)
      .forEach((entry) => recordPosition(entry.target));
  }, { rootMargin: "-20% 0px -55%", threshold: [0, 0.25, 0.6] });

  readerPoems.forEach((poem) => observer.observe(poem));
}

document.querySelectorAll("[data-resume-reading]").forEach((link) => {
  const position = window.localStorage.getItem("spiral-reading-position");
  if (position) {
    link.href = `read/index.html${position}`;
    link.hidden = false;
  }
});
