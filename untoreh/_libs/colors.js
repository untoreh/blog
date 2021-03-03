function toggle_theme() {
  let el = document.body;
  if (el.classList.contains("dark")) {
    el.classList.toggle("dark");
    if (!el.classList.contains("light")) {
      el.classList.add("light");
    }
  } else if (el.classList.contains("light")) {
    el.classList.toggle("light");
    if (!el.classList.contains("dark")) {
      el.classList.add("dark");
    }
  } else {
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      if (!el.classList.contains("dark")) {
        el.classList.add("dark");
      }
    } else {
      if (!el.classList.contains("light")) {
        el.classList.add("light");
      }
    }
  }
}
