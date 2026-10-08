// 가계부: 항목·금액을 적으면 이번 달 합계를 보여 준다 (저장 이름 "budget")
(function () {
  var entries = store.load("budget");
  var list = document.getElementById("budget-list");
  function thisMonth() { return new Date().toISOString().slice(0, 7); }
  function render() {
    list.innerHTML = "";
    var total = 0;
    entries.forEach(function (entry, index) {
      if (entry.month === thisMonth()) total += entry.amount;
      var li = document.createElement("li");
      var span = document.createElement("span"); span.textContent = entry.month + " · " + entry.item;
      var amount = document.createElement("b"); amount.textContent = entry.amount.toLocaleString("ko-KR") + "원";
      var del = document.createElement("button"); del.className = "del"; del.textContent = "×"; del.title = "지우기";
      del.onclick = function () { entries.splice(index, 1); store.save("budget", entries); render(); };
      li.append(span, amount, del); list.append(li);
    });
    document.getElementById("budget-total").textContent = "이번 달 합계 " + total.toLocaleString("ko-KR") + "원";
  }
  document.getElementById("budget-form").addEventListener("submit", function (event) {
    event.preventDefault();
    var item = document.getElementById("budget-item"), amount = document.getElementById("budget-amount");
    var value = parseInt(amount.value, 10);
    if (item.value.trim() && value > 0) {
      entries.unshift({ month: thisMonth(), item: item.value.trim(), amount: value });
      item.value = ""; amount.value = ""; store.save("budget", entries); render();
    }
  });
  render();
})();
