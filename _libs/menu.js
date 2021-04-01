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
  let sty = $("#site-nav .vert").style;
  sty["max-height"] = "0rem";
  sty["filter"] = "blur(1rem)";
};
