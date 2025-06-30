require "sinatra"
require "sinatra/reloader"

$todos = []

# getリクエスト = ブラウザ(ChromeやSafari)がサーバーに「このページの内容をください」とお願いするリクエスト
# "/"に対してgetリクエストを送ってきたらブロックの処理をしますよ
# aタグはgetリクエストを送る
get "/" do
  <<~HTML
  <html lang="ja">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
  </head>
  <style>
    .done {
      text-decoration: line-through;
    }
  </style>
  <body>
    <form action="/add" method="post">
      <input name="task" type="text">
      <input type="submit">
    </form>
    <ul>
    #{$todos.each_with_index.map do |t, i|
    checked = t[:done] ? "checked" : ""
    done_class = t[:done] == true ? "done" : ""
    # onchange =JSのイベント属性 チェックボックスの値が変わったときに動くイベント
    # this.form.submit() = ここではinput要素のあるform要素のフォームを送信 となる
    <<~ITEM
      <li class = "#{done_class}">
        <form action="/toggle/#{i}" method="post" style="display:inline">
          <input type="checkbox" onchange="this.form.submit()" #{checked}>
        </form>
        #{t[:name]}
        <a href="/delete/#{i}">削除</a>
      </li>
    ITEM
    end.join}
    </ul>
  </body>
  </html>
  HTML
end

# "/add"にpostリクエストが送られた時に実行
post "/add" do
  $todos << { name: params[:task], done: false}
  redirect "/"
end

get "/delete/:id" do
  # sinatraではシンボルで値を受け取ると文字列になってしまう仕様のため.to_iで整数化
  id = params[:id].to_i
  $todos.delete_at(id) if id >= 0 && id < $todos.size
  redirect "/"
end

post "/toggle/:id" do 
  id = params[:id].to_i
  $todos[id][:done] = !$todos[id][:done]
  redirect "/"
end