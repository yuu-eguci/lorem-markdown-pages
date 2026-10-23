// jekyll-theme-leap-day 0.2.0 の main.js を基に、 kramdown が付けた見出しの id をそのまま使います (日本語の見出しでもナビのリンクが効きます)。
var sectionHeight = function() {
  var total    = $(window).height(),
      $section = $('section').css('height','auto');

  if ($section.outerHeight(true) < total) {
    var margin = $section.outerHeight(true) - $section.height();
    $section.height(total - margin - 20);
  } else {
    $section.css('height','auto');
  }
}

$(window).resize(sectionHeight);

$(function() {
  $("section h1, section h2, section h3").each(function(){
    $("nav ul").append($("<li>", {"class": "tag-" + this.nodeName.toLowerCase()}).append($("<a>", {href: "#" + this.id, text: $(this).text()})));
    $("nav ul li:first-child a").parent().addClass("active");
  });

  $("nav ul li").on("click", "a", function(event) {
    var position = $(document.getElementById($(this).attr("href").slice(1))).offset().top - 190;
    $("html, body").animate({scrollTop: position}, 400);
    $("nav ul li a").parent().removeClass("active");
    $(this).parent().addClass("active");
    event.preventDefault();
  });

  sectionHeight();

  $('img').on('load', sectionHeight);
});
