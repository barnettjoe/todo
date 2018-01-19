require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def complete?(list)
    unfinished(list).zero? && list[:todos].size > 0
  end

  def unfinished(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def list_class(list)
    "complete" if complete?(list)
  end

  def unfinished_first(lists, sort_by)
    [false, true].each do |bool|
      lists.each_with_index do |list, idx|
        yield(list, idx) if sort_by.call(list) == bool
      end
    end
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
  @list_names = @lists.map { |list| list[:name] }
end

get '/' do
  redirect '/lists'
end

# GET  /lists     -> view all lists
# GET  /lists/new -> new list form
# POST /lists     -> create new list
# GET  /lists/1   -> view a single list

# view list of lists
get '/lists' do
  erb :lists, layout: :layout
end

# render new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end


# update existing todo list

post '/lists/:list_id' do

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@list_id}"
  end
end

# create new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# returns an error message if the name is invalid. return nil if name is valid
def error_for_list_name(list_name)
  if !list_name.size.between?(1, 100)
    'The list name must be between 1 and 100 characters.'
  elsif @list_names.any? { |name| name == list_name }
    'The list name must be unique.'
  end
end

# render page for individual list
get '/lists/:list_id' do

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  erb :list, layout: :layout
end

# render page for editing existing todo list
get '/lists/:list_id/edit' do

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  erb :edit_list, layout: :layout
end

# delete list

post '/lists/:list_id/destroy' do

  @list_id = params[:list_id].to_i

  @lists.delete_at(@list_id)
  session[:success] = 'The list has been deleted.'
  redirect "/lists"
end


# add a new todo to a list
post '/lists/:list_id/todos' do

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

def error_for_todo_name(new_todo_name)
  if !new_todo_name.size.between?(1, 100)
    'The todo name must be between 1 and 100 characters.'
  end
end

# delete a todo

post '/lists/:list_id/todos/:todo_id/destroy' do

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  @todo_id = params[:todo_id].to_i

  @list[:todos].delete_at(@todo_id)
  session[:success] = 'The todo has been deleted.'
  redirect "/lists/#{@list_id}"
end

# check or uncheck todo completion box

post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  @todo_id = params[:todo_id].to_i
  @todo = @list[:todos][@todo_id]
  @todo[:completed] = (params[:completed] == "true")
  session[:success] = 'The todo has been updated.'
  redirect "/lists/#{@list_id}"
end

# mark all todos from list as complete

post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = 'All todos have been completed.'
  redirect "/lists/#{@list_id}"
end