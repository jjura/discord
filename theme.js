const style = document.createElement("style");

style.innerHTML = `
    * {
        font-family: "Terminus (TTF)" !important;
        font-size: 12px !important;
        font-weight: normal !important;
    }`;

document.head.appendChild(style);
document.body.classList.toggle("theme-amoled");
