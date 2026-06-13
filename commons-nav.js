/* commons-nav.js — mobile navigation toggle
   Injects a "menu" button into .site-nav-inner and handles expand/collapse.
   Design system: mono font, terra hover, keyboard + screen-reader accessible.
   Loaded with defer; safe on all pages that use .site-nav.            */

(function () {
  var inner = document.querySelector('.site-nav-inner');
  var links = document.querySelector('.nav-links');
  if (!inner || !links) return;

  links.id = 'nav-links';

  var btn = document.createElement('button');
  btn.className  = 'nav-toggle';
  btn.id         = 'navToggle';
  btn.textContent = 'menu';
  btn.setAttribute('aria-label',    'Open navigation menu');
  btn.setAttribute('aria-expanded', 'false');
  btn.setAttribute('aria-controls', 'nav-links');
  inner.appendChild(btn);

  function open() {
    links.classList.add('is-open');
    btn.setAttribute('aria-expanded', 'true');
    btn.setAttribute('aria-label', 'Close navigation menu');
    btn.textContent = 'close';
  }

  function close() {
    links.classList.remove('is-open');
    btn.setAttribute('aria-expanded', 'false');
    btn.setAttribute('aria-label', 'Open navigation menu');
    btn.textContent = 'menu';
  }

  btn.addEventListener('click', function () {
    if (links.classList.contains('is-open')) { close(); } else { open(); }
  });

  /* close on any nav link click */
  links.addEventListener('click', function (e) {
    if (e.target.tagName === 'A') { close(); }
  });

  /* close on Escape */
  document.addEventListener('keydown', function (e) {
    if ((e.key === 'Escape' || e.key === 'Esc') && links.classList.contains('is-open')) {
      close();
      btn.focus();
    }
  });

  /* close on outside click */
  document.addEventListener('click', function (e) {
    if (!inner.contains(e.target) && links.classList.contains('is-open')) { close(); }
  });
})();
