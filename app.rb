require "sinatra"
require "sinatra/reloader"
require "mysql2"
require "bcrypt"
# -理解していない部分-
require "securerandom"
require "dotenv/load"
require "sinatra/activerecord"

secret_key = ENV["SECRET_KEY"]

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: secret_key
# ---

set :database, {
  adapter: "mysql2",
  host:    "localhost",
  username:"root",
  password:"",
  database:"todo_app",
  encoding:"utf8mb4"
}

class Todo < ActiveRecord::Base
  belongs_to :category
  belongs_to :user
end
class Category < ActiveRecord::Base
  has_many :todos
end
class User < ActiveRecord::Base
  has_many :todos
end

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
  existing_user = User.find_by(email: email)
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
    User.create(name: name, email: email, password_digest: password_digest)
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
  user = User.find_by(email: email)
  if user && BCrypt::Password.new(user[:password_digest]) == password
    session[:user_id] = user[:id]
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

get "/" do
  @current_user = nil
  if session[:user_id]
    @current_user = User.find_by(id: session[:user_id])
  end
  @categories = Category.select(:id, :name)
  @todos = Todo.joins(:category).where(user_id: session[:user_id]).map do |t| {
    id: t.id,
    task_name: t.name,
    category_name: t.category.name,
    checked: t.is_completed ? "checked" : "",
    is_completed_class: t.is_completed ? "completed" : ""
  }
  end
  erb :index
end

post "/tasks" do
  task = params[:task]
  category_id = params[:category_id].to_i
  user_id = session[:user_id]
  Todo.create(name: task, category_id: category_id, user_id: user_id)
  redirect "/"
end

delete "/tasks/:id" do
  id = params[:id].to_i
  user_id = session[:user_id]
  todo = Todo.find_by(id: id, user_id: user_id)
  todo.destroy if todo
  redirect "/"
end


patch "/tasks/:id" do 
  id = params[:id].to_i
  user_id = session[:user_id]
  todo = Todo.find_by(id: id, user_id: user_id)
  if todo
    todo.update(is_completed: !todo.is_completed)
  end
  redirect "/"
end