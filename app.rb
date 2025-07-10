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
    .flex {
      display:flex;
    }
  </style>
  <body>
    <form action="/tasks" method="post">
      <input name="task" type="text">
      <select name="category_id">
        #{DB.query("SELECT id, name FROM categories").map do |c|
          "<option value='#{c[:id]}'>#{c[:name]}</option>"
        end.join}
      </select>
      <input type="submit">
    </form>
    <ul>
    #{DB.query("
      SELECT todos.*, categories.name AS category_name
      FROM todos
      INNER JOIN categories ON todos.category_id = categories.id
    ").map do |t|
    checked = ""
    done_class = ""
    if t[:done].to_i == 1
      checked = "checked"
      done_class = "done"
    end
    task_id = t[:id].to_i
    # onchange =JSのイベント属性 チェックボックスの値が変わったときに動くイベント
    # this.form.submit() = ここではinput要素のあるform要素のフォームを送信 となる
    <<~ITEM
      <li class = "#{done_class} flex">
        <form action="/tasks/#{task_id}" method="post">
          <input type="hidden" name="_method" value="patch">
          <input type="checkbox" onchange="this.form.submit()" #{checked}>
        </form>
        #{t[:name]}（カテゴリ：#{t[:category_name]}）
        <form action="/tasks/#{task_id}" method="post">
          <input type="hidden" name="_method" value="delete">
          <button type="submit">削除</button>
        </form>
      </li>
    ITEM
    end.join}
    </ul>
  </body>
  </html>
  HTML
end


post "/tasks" do
  task = params[:task]
  category_id = params[:category_id].to_i
  DB.query("INSERT INTO todos (name, category_id) VALUES ('#{DB.escape(task)}', #{category_id})")
  redirect "/"
end

# .escapeは文字列をエスケープするメソッド to_sは文字列化するメソッド
delete "/tasks/:id" do
  id = params[:id].to_i
  query = DB.prepare("DELETE FROM todos WHERE id = ?")
  query.execute(id)
  redirect "/"
end

patch "/tasks/:id" do 
  id = params[:id].to_i
  result = DB.query("SELECT done FROM todos WHERE id = #{id}").first
  done = result[:done].to_i
  if done == 0 then
    done = 1
  else
    done = 0
  end
  DB.query("UPDATE todos SET done = #{done} WHERE id = #{id}")
  redirect "/"
end