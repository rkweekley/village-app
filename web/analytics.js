// Google Analytics 4 configuration.
// Kept in an external file so the CSP can stay strict (no 'unsafe-inline' in
// script-src). The dataLayer queue pattern lets this run before or after the
// async gtag.js library finishes loading.
window.dataLayer = window.dataLayer || [];
function gtag() { dataLayer.push(arguments); }
gtag('js', new Date());
gtag('config', 'G-EZ6VK01WFM');
