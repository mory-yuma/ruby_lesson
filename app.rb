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
  @categories = DB.query("SELECT id, name FROM categories")
  @todos = DB.query("
      SELECT todos.*, categories.name AS category_name
      FROM todos
      INNER JOIN categories ON todos.category_id = categories.id
    ")
  erb :index
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
  result = DB.query("SELECT is_completed FROM todos WHERE id = #{id}").first
  is_completed = result[:is_completed].to_i
  if is_completed == 0 then
    is_completed = 1
  else
    is_completed = 0
  end
  DB.query("UPDATE todos SET is_completed = #{is_completed} WHERE id = #{id}")
  redirect "/"
end