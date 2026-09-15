const poemLinks = __POEM_LINKS__;

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
