// 메모: 적고, 지우고, 새로고침해도 남는다 (localStorage "memo")
(function () {
  var memos = store.load("memo");
  var list = document.getElementById("memo-list");
  function save() { store.save("memo", memos); }
  function render() {
    list.innerHTML = "";
    memos.forEach(function (text, index) {
      var li = document.createElement("li");
      var span = document.createElement("span"); span.textContent = text;
      var del = document.createElement("button"); del.className = "del"; del.textContent = "×"; del.title = "지우기";
      del.onclick = function () { memos.splice(index, 1); save(); render(); };
      li.append(span, del); list.append(li);
    });
  }
  document.getElementById("memo-form").addEventListener("submit", function (event) {
    event.preventDefault();
    var input = document.getElementById("memo-input");
    if (input.value.trim()) { memos.unshift(input.value.trim()); input.value = ""; save(); render(); }
  });
  render();
})();
