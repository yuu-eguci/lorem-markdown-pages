"use strict";
// jekyll-theme-leap-day 0.2.0 の main.js を基に、 kramdown が付けた見出しの id をそのまま使います (日本語の見出しでもナビのリンクが効きます)。
// assets/js/main.js はこのファイルから tsc で生成します。 main.js は直接編集しないでください。
const sectionHeight = () => {
    const total = $(window).height() ?? 0;
    const $section = $("section").css("height", "auto");
    const outerHeight = $section.outerHeight(true) ?? 0;
    if (outerHeight < total) {
        const margin = outerHeight - ($section.height() ?? 0);
        $section.height(total - margin - 20);
    }
};
$(window).on("resize", sectionHeight);
$(() => {
    $("section h1, section h2, section h3").each(function () {
        $("nav ul").append($("<li>", { class: `tag-${this.nodeName.toLowerCase()}` }).append($("<a>", { href: `#${this.id}`, text: $(this).text() })));
    });
    $("nav ul li:first-child a").parent().addClass("active");
    $("nav ul li").on("click", "a", function (event) {
        const heading = document.getElementById($(this).attr("href")?.slice(1) ?? "");
        if (heading === null) {
            return;
        }
        const position = ($(heading).offset()?.top ?? 0) - 190;
        $("html, body").animate({ scrollTop: position }, 400);
        $("nav ul li a").parent().removeClass("active");
        $(this).parent().addClass("active");
        event.preventDefault();
    });
    sectionHeight();
    $("img").on("load", sectionHeight);
});
