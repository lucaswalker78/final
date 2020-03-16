# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

location_table = DB.from(:location)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of events (aka "index")
get "/" do
    puts "params: #{params}"

    @location = location_table.all.to_a
    pp @location

    view "locations"
end

# event details (aka "show")
get "/location/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @location = location_table.where(id: params[:id]).to_a[0]
    pp @location

    @reviews = reviews_table.where(location_id: @location[:id]).to_a
    @reviews_count = reviews_table.where(location_id: @location[:id], worth_going_to: true).count

    view "location"
end

# display the reviews form (aka "new")
get "/location/:id/review/new" do
    puts "params: #{params}"

    @location = location_table.where(id: params[:id]).to_a[0]
    view "new_review"
end

# receive the submitted rsvp form (aka "create")
post "/location/:id/review/create" do
    puts "params: #{params}"

    # first find the event that rsvp'ing for
    @location = location_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvps table with the rsvp form data
    reviews_table.insert(
        location_id: @location[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        worth_going_to: params["worth_going_to"]
    )

    redirect "/location/#{@location[:id]}"
end

# display the review form (aka "edit")
get "/review/:id/edit" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @location = location_table.where(id: review[:location_id]).to_a[0]
    view "edit_review"
end

# receive the submitted review form (aka "update")
post "/review/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @review = reviews_table.where(id: params["id"]).to_a[0]
    # find the rsvp's event
    @location = location_table.where(id: @review[:location_id]).to_a[0]

    if @current_user && @current_user[:id] == @reviews[:id]
        reviews_table.where(id: params["id"]).update(
            worth_going_to: params["worth_going_to"],
            comments: params["comments"]
        )

        redirect "/location/#{@location[:id]}"
    else
        view "error"
    end
end

# delete the review (aka "destroy")
get "/review/:id/destroy" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @location = location_table.where(id: review[:location_id]).to_a[0]

    reviews_table.where(id: params["id"]).delete

    redirect "/location/#{@location[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end