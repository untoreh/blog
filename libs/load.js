window.onload = function () {
  toggleTheme();
  if (typeof queryLunr === "function") {
    queryLunr();
  }
};
