/* Финтакса — простая навигация по разделам через хеш */
(function () {
  "use strict";

  var VIEWS = ["home", "stories", "about", "story"];
  var DEFAULT_STORY = "kak-taksa-stala-fintaksоy";
  var TITLES = {
    home: "Финтакса — истории таксы о финансах и налогах",
    stories: "Все истории — Финтакса",
    about: "О Финтаксе",
    story: "Как такса стала Финтаксой — Финтакса",
    "story/nalogi-ne-strashno": "Налоги — это не страшно — Финтакса",
    "story/pyat-stavok-ndfl": "Пять ступенек налога — Финтакса",
    "story/vychety-lukerya-petrovna": "Государство возвращает! История про вычеты — Финтакса",
    "story/porfiriy-ipoteka-vychet": "Финтакса и ипотека Порфирия Сергеевича — Финтакса"
  };

  var views = document.querySelectorAll(".view");
  var navLinks = document.querySelectorAll("[data-nav]");

  function parseHash() {
    var raw = window.location.hash.replace(/^#\/?/, "");
    if (!raw) return "home";

    var name = raw.split("/")[0];
    if (VIEWS.indexOf(name) === -1) return "home";
    if (name === "story") {
      var slug = raw.split("/")[1] || DEFAULT_STORY;
      return document.getElementById("view-story-" + slug) ? "story/" + slug : "story";
    }
    return name;
  }

  function render(scrollToTop) {
    var name = parseHash();
    var target = document.getElementById("view-" + name.replace("/", "-")) ||
                 document.getElementById("view-story") ||
                 document.getElementById("view-home");

    for (var i = 0; i < views.length; i++) {
      if (views[i] === target) {
        views[i].classList.add("is-active");
      } else {
        views[i].classList.remove("is-active");
      }
    }

    for (var j = 0; j < navLinks.length; j++) {
      if (navLinks[j].getAttribute("data-nav") === name) {
        navLinks[j].setAttribute("aria-current", "page");
      } else {
        navLinks[j].removeAttribute("aria-current");
      }
    }

    document.title = TITLES[name] || TITLES.home;

    if (scrollToTop) window.scrollTo(0, 0);
  }

  window.addEventListener("hashchange", function () {
    render(true);
  });

  render(false);
})();
