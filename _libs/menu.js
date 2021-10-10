function $(a, doc = window.document) {
  return doc.querySelector(a);
}

function $$(a, doc = window.document) {
  return doc.querySelectorAll(a);
}

$("#site-nav .ham").onclick = function (e) {
  e.stopPropagation();
  toggle_menu();
};

$("body,html").onclick = function (e) {
  cls = e.target.classList;
  e.stopPropagation();
  if (cls.contains("langs-dropdown-wrapper")) {
    toggle_langs();
  } else {
    if (!cls.contains("search-input")) {
      toggle_menu((hide = true));
    }
  }
};

menu_visible = false;
function toggle_menu(hide = false) {
  nav = $("#site-nav");
  let sty = $(".vert", nav).style;
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
  toggle_langs(hide=true)
}


function toggle_langs(hide = false) {
  langs = $$(".langs-dropdown-content")
  for (k in Object.keys(langs)) {
    if (hide) {
      langs[k].classList.remove("show");
    } else {
      langs[k].classList.toggle("show");
    }
  }
}

$(".langs-dropdown-wrapper").onclick = function (e) {
  e.stopPropagation();
  toggle_langs();
};
