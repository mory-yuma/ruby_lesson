require "sinatra"
require "sinatra/reloader"
require "mysql2"
require "bcrypt"
# -理解していない部分-
require "securerandom"
require "dotenv/load"

secret_key = ENV["SECRET_KEY"]

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: secret_key
# ---

DB = Mysql2::Client.new(
  host: "localhost",
  username: "root",
  password: "",
  database: "todo_app", 
  symbolize_keys: true      # 結果のキーを文字列でなくシンボルで返す（:name など）
)

# signup
get "/signup" do
  erb :signup
end
# signup処理
EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
post "/signup" do
  name = params[:name]
  email = params[:email]
  password = params[:password]
  stmt = DB.prepare("SELECT * FROM users WHERE email = ?")
  existing_user = stmt.execute(email).first
  errors = []
  errors << "メールアドレスは必須です。" if email.nil? || email.strip.empty?
  errors << "メールアドレスの形式が正しくありません。" if email && !(email =~ EMAIL_REGEX)
  errors << "そのメールアドレスはすでに登録されています。" if existing_user
  errors << "パスワードは必須です。" if password.nil? || password.strip.empty?
  errors << "パスワードは4桁以上にしてください。" if password && password.length < 4
  if errors.any?
    @errors = errors
    erb :signup
  else 
    password_digest = BCrypt::Password.create(password)
    stmt = DB.prepare("INSERT INTO users (name,email,password_digest) VALUES (?,?,?)")
    stmt.execute(name,email,password_digest)
    redirect "/login"
  end
end

#login
get "/login" do
  erb :login
end
# login処理
post "/login" do
  email = params[:email]
  password = params[:password]
  stmt = DB.prepare("SELECT * FROM users WHERE email = ?")
  result = stmt.execute(email).first
  if result && BCrypt::Password.new(result[:password_digest]) == password
    session[:user_id] = result[:id]
    redirect "/"
  else
    "メールアドレスまたはパスワードが間違っています"
  end
end

# logout処理
post "/logout" do
  session.clear
  redirect "/"
end

# getリクエスト = ブラウザ(ChromeやSafari)がサーバーに「このページの内容をください」とお願いするリクエスト
# "/"に対してgetリクエストを送ってきたらブロックの処理をしますよ
# aタグはgetリクエストを送る
get "/" do
  @current_user = nil
  if session[:user_id]
    stmt = DB.prepare("SELECT * FROM users WHERE id = ?")
    @current_user = stmt.execute(session[:user_id]).first
  end
  @categories = DB.query("SELECT id, name FROM categories")
  stmt = DB.prepare("
      SELECT todos.*, categories.name AS category_name
      FROM todos
      INNER JOIN categories ON todos.category_id = categories.id
      WHERE todos.user_id = ?
    ")
    @todos = stmt.execute(session[:user_id]).map do |t| {
      id: t[:id],
      task_name: t[:name],
      category_name: t[:category_name],
      checked: t[:is_completed].to_i == 1 ? "checked" : "",
      is_completed_class: t[:is_completed].to_i == 1 ? "completed" : ""
    }
  end
  erb :index
end

post "/tasks" do
  task = params[:task]
  category_id = params[:category_id].to_i
  user_id = session[:user_id]
  stmt = DB.prepare("INSERT INTO todos (name, category_id, user_id) VALUES (?,?,?)")
  stmt.execute(task, category_id, user_id)
  redirect "/"
end

# .escapeは文字列をエスケープするメソッド to_sは文字列化するメソッド
delete "/tasks/:id" do
  id = params[:id].to_i
  user_id = session[:user_id]
  stmt = DB.prepare("DELETE FROM todos WHERE id = ? AND user_id = ?")
  stmt.execute(id, user_id)
  redirect "/"
end


patch "/tasks/:id" do 
  id = params[:id].to_i
  user_id = session[:user_id]
  stmt = DB.prepare("SELECT is_completed FROM todos WHERE id = ? AND user_id = ?")
  result = stmt.execute(id, user_id).first
  is_completed = result[:is_completed].to_i
  if is_completed == 0 then
    is_completed = 1
  else
    is_completed = 0
  end
  DB.prepare("UPDATE todos SET is_completed = ? WHERE id = ? AND user_id = ?").execute(is_completed,id, user_id)
  redirect "/"
end