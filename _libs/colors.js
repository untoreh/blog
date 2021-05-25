let utterances_theme = window.matchMedia("(prefers-color-scheme: dark)").matches
  ? "dark-blue"
  : "boxy-light";
function update_utterances_theme(toggle = false) {
  const message = {
    type: "set-theme",
    theme: utterances_theme,
  };
  const utterances = document.querySelector("iframe").contentWindow; // try event.source instead
  utterances.postMessage(message, "https://utteranc.es");
}

function toggle_theme() {
  let el = document.body;
  if (el.classList.contains("dark")) {
    utterances_theme = "boxy-light";
    el.classList.toggle("dark");
    if (!el.classList.contains("light")) {
      el.classList.add("light");
    }
  } else if (el.classList.contains("light")) {
    utterances_theme = "dark-blue";
    el.classList.toggle("light");
    if (!el.classList.contains("dark")) {
      el.classList.add("dark");
    }
  } else {
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      utterances_theme = "dark-blue";
      if (!el.classList.contains("dark")) {
        el.classList.add("dark");
      }
    } else {
      utterances_theme = "boxy-light";
      if (!el.classList.contains("light")) {
        el.classList.add("light");
      }
    }
  }
  update_utterances_theme();
}
