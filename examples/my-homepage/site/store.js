// 저장 도우미 (모든 기능이 함께 씀): 브라우저 localStorage 에 목록을 읽고 쓴다
// 저장 이름은 기능 이름 그대로 ("memo", "todo", "budget") -- 바꾸면 예전에 쓴 내용이 안 보이게 된다
var store = {
  load: function (name) { return JSON.parse(localStorage.getItem(name) || "[]"); },
  save: function (name, items) { localStorage.setItem(name, JSON.stringify(items)); }
};
