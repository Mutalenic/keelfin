// Theme toggle: persists the user's light/dark choice in localStorage and
// applies it via the data-theme attribute on <html>. The initial value is
// set by an inline no-flash script in the <head>; this file only wires up
// the toggle button and keeps the UI in sync.
(function () {
  var STORAGE_KEY = "keelfin-theme";

  function systemTheme() {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches
      ? "light"
      : "dark";
  }

  function currentTheme() {
    return document.documentElement.getAttribute("data-theme") || systemTheme();
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {
      /* storage unavailable — non-fatal */
    }
    updateToggles(theme);
  }

  function updateToggles(theme) {
    var isDark = theme === "dark";
    document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
      var sun = btn.querySelector("[data-theme-icon='sun']");
      var moon = btn.querySelector("[data-theme-icon='moon']");
      if (sun) sun.classList.toggle("hidden", !isDark); // show sun in dark mode (click -> light)
      if (moon) moon.classList.toggle("hidden", isDark);
      btn.setAttribute("aria-pressed", String(isDark));
      btn.setAttribute(
        "aria-label",
        isDark ? "Switch to light theme" : "Switch to dark theme"
      );
    });
  }

  function toggleTheme() {
    applyTheme(currentTheme() === "dark" ? "light" : "dark");
  }

  function bind() {
    updateToggles(currentTheme());
    document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
      if (btn.dataset.themeBound) return;
      btn.dataset.themeBound = "true";
      btn.addEventListener("click", toggleTheme);
    });
  }

  document.addEventListener("DOMContentLoaded", bind);
  // Turbo: re-bind after navigations
  document.addEventListener("turbo:load", bind);

  // Sidebar toggle fallback: some browsers don't let transform override
  // the translate property set by Tailwind v4, so we also toggle a class.
  function initSidebarToggle() {
    var toggleInput = document.getElementById("sidebar-toggle");
    var panel = document.querySelector(".sidebar-panel");
    if (!toggleInput || !panel) return;

    toggleInput.addEventListener("change", function () {
      panel.classList.toggle("sidebar-open", toggleInput.checked);
    });
  }

  document.addEventListener("DOMContentLoaded", initSidebarToggle);
  document.addEventListener("turbo:load", initSidebarToggle);
})();
