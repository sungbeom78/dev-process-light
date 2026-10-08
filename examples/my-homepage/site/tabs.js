// 상단 탭 전환 (모든 기능이 함께 씀)
document.querySelectorAll("nav button").forEach(function (button) {
  button.addEventListener("click", function () {
    document.querySelectorAll("nav button, .tab").forEach(function (el) { el.classList.remove("on"); });
    button.classList.add("on");
    document.getElementById(button.dataset.tab).classList.add("on");
  });
});
