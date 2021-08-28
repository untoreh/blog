function $(a) {
  return document.querySelector(a);
}
$("#site-nav .ham").onclick = function (e) {
  e.stopPropagation();
  let sty = $("#site-nav .vert").style;
  sty["max-height"] = "30rem";
  sty["filter"] = "none";
};
$("body,html").onclick = function (e) {
  e.stopPropagation();
  if (e.target.className !== "search-input") {
    let sty = $("#site-nav .vert").style;
    sty["max-height"] = "0rem";
    sty["filter"] = "blur(1rem)";
    let langs = $("#langs-dropdown-menu")
    if (langs.classList.contains("show")) {
      langs.classList.toggle("show")
    }
  }
};
$(".langs-dropdown-wrapper").onclick = function (e) {
  e.stopPropagation();
  $("#langs-dropdown-menu").classList.toggle("show");
}
