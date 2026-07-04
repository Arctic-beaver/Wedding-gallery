const photos = window.WEDDING_PHOTOS || [];

const galleryGrid = document.getElementById("galleryGrid");
const lightbox = document.getElementById("lightbox");
const lightboxImage = document.getElementById("lightboxImage");
const lightboxCaption = document.getElementById("lightboxCaption");
const lightboxDownload = document.getElementById("lightboxDownload");
const closeLightboxButton = document.getElementById("closeLightbox");
const previousButton = document.getElementById("prevPhoto");
const nextButton = document.getElementById("nextPhoto");

let currentPhotoIndex = 0;

function renderGallery() {
  if (!photos.length) {
    galleryGrid.innerHTML = `<p class="empty-state">Фотографии пока не добавлены.</p>`;
    return;
  }

  galleryGrid.innerHTML = photos
    .map((photo, index) => {
      return `
        <article class="photo-card">
          <button class="photo-card__image-button" type="button" data-index="${index}" aria-label="Открыть ${photo.title}">
            <img src="${photo.thumb}" alt="${photo.title}" loading="lazy" />
          </button>
          <div class="photo-card__footer">
            <span>${photo.title}</span>
            <a href="${photo.download}" download>Скачать</a>
          </div>
        </article>
      `;
    })
    .join("");

  document.querySelectorAll(".photo-card__image-button").forEach((button) => {
    button.addEventListener("click", () => {
      openLightbox(Number(button.dataset.index));
    });
  });
}

function openLightbox(index) {
  currentPhotoIndex = index;
  const photo = photos[currentPhotoIndex];

  lightboxImage.src = photo.full;
  lightboxImage.alt = photo.title;
  lightboxCaption.textContent = photo.title;
  lightboxDownload.href = photo.download;

  lightbox.setAttribute("aria-hidden", "false");
  document.body.classList.add("is-lightbox-open");
}

function closeLightbox() {
  lightbox.setAttribute("aria-hidden", "true");
  document.body.classList.remove("is-lightbox-open");
  lightboxImage.src = "";
}

function showPreviousPhoto() {
  const previousIndex = currentPhotoIndex === 0 ? photos.length - 1 : currentPhotoIndex - 1;
  openLightbox(previousIndex);
}

function showNextPhoto() {
  const nextIndex = currentPhotoIndex === photos.length - 1 ? 0 : currentPhotoIndex + 1;
  openLightbox(nextIndex);
}

closeLightboxButton.addEventListener("click", closeLightbox);
previousButton.addEventListener("click", showPreviousPhoto);
nextButton.addEventListener("click", showNextPhoto);

lightbox.addEventListener("click", (event) => {
  if (event.target === lightbox) {
    closeLightbox();
  }
});

document.addEventListener("keydown", (event) => {
  if (lightbox.getAttribute("aria-hidden") === "true") {
    return;
  }

  if (event.key === "Escape") closeLightbox();
  if (event.key === "ArrowLeft") showPreviousPhoto();
  if (event.key === "ArrowRight") showNextPhoto();
});

renderGallery();
