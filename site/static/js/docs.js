(function () {
  "use strict";

  document.querySelectorAll(".docs-filter").forEach(function (input) {
    input.addEventListener("input", function () {
      var query = input.value.trim().toLowerCase();
      var panel = input.closest(".docs-nav-panel");

      panel.querySelectorAll(".docs-tree-section").forEach(function (section) {
        var links = section.querySelectorAll("a");
        var visible = false;

        links.forEach(function (link) {
          var matches = !query || link.textContent.toLowerCase().indexOf(query) !== -1;
          link.parentElement.hidden = !matches;
          visible = visible || matches;
        });

        // A top-level section can itself contain subsections (chapter
        // groupings, e.g. "Auth" within "Development") rather than
        // linking directly to pages. The loop above already hid every
        // non-matching page's <li>; a subsection whose pages were all
        // hidden that way needs hiding too, or its own header is left
        // showing above an empty list.
        section.querySelectorAll(".docs-tree-subsection").forEach(function (subsection) {
          var subsectionVisible = Array.prototype.some.call(
            subsection.querySelectorAll("a"),
            function (link) { return !link.parentElement.hidden; }
          );
          subsection.hidden = !subsectionVisible;
        });

        section.hidden = !visible;
      });
    });
  });
}());
