function $(a) {
  return document.querySelector(a);
}
$("#site-nav .ham").onclick = function (e) {
  e.stopPropagation();
  toggle_menu();
};

$("body,html").onclick = function (e) {
  cls = e.target.classList;
  e.stopPropagation();
  if (cls.contains("langs-dropdown-wrapper")) {
    toggle_langs(e);
  } else if (!cls.contains("search-input")) {
    hide_langs();
    toggle_menu(hide=true);
  }
};

menu_visible = false;
function toggle_menu(hide=false) {
  let sty = $("#site-nav .vert").style;
  if (menu_visible) {
    menu_visible = false;
    sty["max-height"] = "0rem";
    sty["filter"] = "blur(1rem)";
    sty["overflow"] = "hidden";
  } else if (!hide) {
    menu_visible = true;
    sty["max-height"] = "30rem";
    sty["filter"] = "none";
    sty["overflow"] = "visible";
  }
}

function hide_langs() {
  langs = $(".langs-dropdown-content");
  if (langs.classList.contains("show")) {
    langs.classList.toggle("show");
  }
}

function toggle_langs(e, hide=false) {
  langs = e.target.querySelector(".langs-dropdown-content");
  menu = $("#site-nav .vert");
  langs.classList.toggle("show");
}
$(".langs-dropdown-wrapper").onclick = function (e) {
  e.stopPropagation();
  toggle_langs(e);
};
