const galleryData = window.WEDDING_GALLERY || { sections: [] };
const sections = galleryData.sections || [];

const heroImage = document.getElementById("heroImage");
const heroDate = document.getElementById("heroDate");
const heroSectionName = document.getElementById("heroSectionName");
const sectionTabs = document.getElementById("sectionTabs");
const galleryTitle = document.getElementById("galleryTitle");
const photoCount = document.getElementById("photoCount");
const featuredSection = document.getElementById("featuredSection");
const featuredGallery = document.getElementById("featuredGallery");
const restSection = document.getElementById("restSection");
const restGallery = document.getElementById("restGallery");
const restCount = document.getElementById("restCount");
const emptyState = document.getElementById("emptyState");
const downloadAll = document.getElementById("downloadAll");
const sectionDownloadHero = document.getElementById("sectionDownloadHero");
const sectionDownloadGallery = document.getElementById("sectionDownloadGallery");
const lightbox = document.getElementById("lightbox");
const lightboxImage = document.getElementById("lightboxImage");
const lightboxCaption = document.getElementById("lightboxCaption");
const lightboxDownload = document.getElementById("lightboxDownload");
const closeLightboxButton = document.getElementById("closeLightbox");
const previousButton = document.getElementById("prevPhoto");
const nextButton = document.getElementById("nextPhoto");

let activeSectionIndex = Math.max(0, sections.findIndex((section) => section.id === location.hash.slice(1)));
let currentPhotoIndex = 0;
let lastFocusedElement = null;

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function pluralizePhotos(count) {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod10 === 1 && mod100 !== 11) return `${count} фотография`;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return `${count} фотографии`;
  return `${count} фотографий`;
}

function getSectionPhotos(section = sections[activeSectionIndex]) {
  return [...(section?.best || []), ...(section?.rest || [])];
}

function setHeroImage(section) {
  if (!section.hero) {
    heroImage.hidden = true;
    return;
  }

  const separator = section.hero.includes("?") ? "&" : "?";
  const version = galleryData.generatedAt || "1";
  const heroUrl = `${section.hero}${separator}v=${encodeURIComponent(version)}`;
  const image = new Image();
  image.onload = () => {
    heroImage.src = heroUrl;
    heroImage.hidden = false;
  };
  image.onerror = () => {
    heroImage.hidden = true;
  };
  image.src = heroUrl;
}

function renderTabs() {
  sectionTabs.innerHTML = sections
    .map((section, index) => `
      <button
        class="tab"
        id="tab-${section.id}"
        type="button"
        role="tab"
        aria-selected="${index === activeSectionIndex}"
        aria-controls="galleryGrid"
        tabindex="${index === activeSectionIndex ? 0 : -1}"
        data-section-index="${index}"
      >${escapeHtml(section.title)}</button>`)
    .join("");

  sectionTabs.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", () => selectSection(Number(tab.dataset.sectionIndex)));
    tab.addEventListener("keydown", handleTabKeydown);
  });
}

function handleTabKeydown(event) {
  if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
  event.preventDefault();

  let nextIndex = activeSectionIndex;
  if (event.key === "ArrowLeft") nextIndex = (activeSectionIndex - 1 + sections.length) % sections.length;
  if (event.key === "ArrowRight") nextIndex = (activeSectionIndex + 1) % sections.length;
  if (event.key === "Home") nextIndex = 0;
  if (event.key === "End") nextIndex = sections.length - 1;

  selectSection(nextIndex, true);
}

function photoCard(photo, index, featured = false) {
  const safeTitle = escapeHtml(photo.title);
  const cardClass = featured ? "featured-card" : "photo-card";
  const buttonClass = featured ? "featured-card__image-button" : "photo-card__image-button";

  return `
    <article class="${cardClass}">
      <button class="${buttonClass} photo-open-button" type="button" data-index="${index}" aria-label="Открыть ${safeTitle}">
        <img src="${photo.thumb}" alt="${safeTitle}" loading="lazy" decoding="async" />
      </button>
      <div class="${featured ? "featured-card__footer" : "photo-card__footer"}">
        ${featured ? '<span class="featured-card__mark">Избранное</span>' : `<span>${safeTitle}</span>`}
        <a href="${photo.download}" download aria-label="Скачать ${safeTitle}">Скачать</a>
      </div>
    </article>`;
}

function renderGallery() {
  const section = sections[activeSectionIndex];
  const best = section?.best || [];
  const rest = section?.rest || [];
  const allPhotos = getSectionPhotos(section);

  galleryTitle.textContent = section?.title || "Фотогалерея";
  heroSectionName.textContent = section?.title || "";
  heroDate.textContent = section?.date || "";
  photoCount.textContent = allPhotos.length ? pluralizePhotos(allPhotos.length) : "Скоро здесь появятся фотографии";
  sectionDownloadHero.href = section?.archive || "#";
  sectionDownloadGallery.href = section?.archive || "#";
  sectionDownloadHero.setAttribute("aria-label", `Скачать все фото раздела «${section?.title || ""}»`);
  sectionDownloadGallery.setAttribute("aria-label", `Скачать все фото раздела «${section?.title || ""}»`);
  setHeroImage(section || {});

  featuredSection.hidden = best.length === 0;
  restSection.hidden = rest.length === 0;
  emptyState.hidden = allPhotos.length !== 0;

  featuredGallery.innerHTML = best.map((photo, index) => photoCard(photo, index, true)).join("");
  restGallery.innerHTML = rest.map((photo, index) => photoCard(photo, best.length + index)).join("");
  restCount.textContent = pluralizePhotos(rest.length);

  document.querySelectorAll(".photo-open-button").forEach((button) => {
    button.addEventListener("click", () => openLightbox(Number(button.dataset.index), button));
  });
}

function selectSection(index, focusTab = false) {
  activeSectionIndex = index;
  currentPhotoIndex = 0;

  sectionTabs.querySelectorAll(".tab").forEach((tab, tabIndex) => {
    const isActive = tabIndex === activeSectionIndex;
    tab.setAttribute("aria-selected", String(isActive));
    tab.tabIndex = isActive ? 0 : -1;
  });

  const section = sections[activeSectionIndex];
  history.replaceState(null, "", `#${section.id}`);
  renderGallery();
  if (focusTab) document.getElementById(`tab-${section.id}`).focus();
}

function getActivePhotos() {
  return getSectionPhotos();
}

function openLightbox(index, trigger) {
  const photos = getActivePhotos();
  if (!photos.length) return;

  currentPhotoIndex = index;
  const photo = photos[currentPhotoIndex];
  if (trigger) lastFocusedElement = trigger;

  lightboxImage.src = photo.full;
  lightboxImage.alt = photo.title;
  lightboxCaption.textContent = `${photo.title} · ${currentPhotoIndex + 1} из ${photos.length}`;
  lightboxDownload.href = photo.download;
  lightbox.setAttribute("aria-hidden", "false");
  document.body.classList.add("is-lightbox-open");
  if (trigger) closeLightboxButton.focus();
}

function closeLightbox() {
  lightbox.setAttribute("aria-hidden", "true");
  document.body.classList.remove("is-lightbox-open");
  lightboxImage.src = "";
  lastFocusedElement?.focus();
}

function showPhoto(offset) {
  const photos = getActivePhotos();
  if (!photos.length) return;
  currentPhotoIndex = (currentPhotoIndex + offset + photos.length) % photos.length;
  openLightbox(currentPhotoIndex);
}

closeLightboxButton.addEventListener("click", closeLightbox);
previousButton.addEventListener("click", () => showPhoto(-1));
nextButton.addEventListener("click", () => showPhoto(1));
lightbox.addEventListener("click", (event) => {
  if (event.target === lightbox) closeLightbox();
});

document.addEventListener("keydown", (event) => {
  if (lightbox.getAttribute("aria-hidden") === "true") return;
  if (event.key === "Escape") closeLightbox();
  if (event.key === "ArrowLeft") showPhoto(-1);
  if (event.key === "ArrowRight") showPhoto(1);
});

downloadAll.href = galleryData.downloadAll || "/photos/downloads/all-photos.zip";
renderTabs();
renderGallery();
