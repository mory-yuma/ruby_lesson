require "sinatra"
require "sinatra/reloader"
require "mysql2"


DB = Mysql2::Client.new(
  host: "localhost",
  username: "root",
  password: "",
  database: "todo_app", 
  symbolize_keys: true      # 結果のキーを文字列でなくシンボルで返す（:name など）
)

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
    #{DB.query('SELECT * FROM todos').map do |t|
    checked = t[:done].to_i == 1 ? "checked" : ""
    done_class = t[:done].to_i == 1 ? "done" : ""
    task_id = t[:id].to_i
    # onchange =JSのイベント属性 チェックボックスの値が変わったときに動くイベント
    # this.form.submit() = ここではinput要素のあるform要素のフォームを送信 となる
    <<~ITEM
      <li class = "#{done_class}">
        <form action="/toggle/#{task_id}" method="post" style="display:inline">
          <input type="checkbox" onchange="this.form.submit()" #{checked}>
        </form>
        #{t[:name]}
        <a href="/delete/#{task_id}">削除</a>
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
  task = params[:task]
  DB.query("INSERT INTO todos (name) VALUES ('#{DB.escape(task)}')")
  redirect "/"
end

# .escapeは文字列をエスケープするメソッド to_sは文字列化するメソッド
get "/delete/:id" do
  id = params[:id].to_i
  DB.query("DELETE FROM todos WHERE id = #{DB.escape(id.to_s)}")
  redirect "/"
end


post "/toggle/:id" do 
  id = params[:id].to_i
  result = DB.query("SELECT done FROM todos WHERE id = #{id}").first
  done = result[:done].to_i
  if done == 0 then
    DB.query("UPDATE todos SET done = 1 WHERE id = #{id}")
  else
    DB.query("UPDATE todos SET done = 0 WHERE id = #{id}")
  end
  redirect "/"
end