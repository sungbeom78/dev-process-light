// 할 일: 적고, 체크하면 줄이 그어지고 목록 맨 아래로, 새로고침해도 남는다 (localStorage "todo")
(function () {
  var todos = store.load("todo");
  var list = document.getElementById("todo-list");
  function save() { store.save("todo", todos); }
  function render() {
    list.innerHTML = "";
    var order = todos.map(function (todo, index) { return index; });
    order.sort(function (a, b) { return (todos[a].done - todos[b].done) || (a - b); });   // 끝난 일은 아래로
    order.forEach(function (index) {
      var todo = todos[index];
      var li = document.createElement("li"); if (todo.done) li.className = "done";
      var check = document.createElement("input"); check.type = "checkbox"; check.checked = todo.done;
      check.onchange = function () { todo.done = check.checked; save(); render(); };
      var span = document.createElement("span"); span.textContent = todo.text;
      var del = document.createElement("button"); del.className = "del"; del.textContent = "×"; del.title = "지우기";
      del.onclick = function () { todos.splice(index, 1); save(); render(); };
      li.append(check, span, del); list.append(li);
    });
  }
  document.getElementById("todo-form").addEventListener("submit", function (event) {
    event.preventDefault();
    var input = document.getElementById("todo-input");
    if (input.value.trim()) { todos.unshift({ text: input.value.trim(), done: false }); input.value = ""; save(); render(); }
  });
  render();
})();
