# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :location do
  primary_key :id
  String :name
  String :description, text: true
  String :style
  String :neighborhood
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :location_id
  foreign_key :user_id
  Boolean :worth_going_to
  String :name
  String :comments, text: true
end

DB.create_table! :users do
  primary_key :id
  foreign_key :reviews_id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
location_table = DB.from(:location)

location_table.insert(name: "Hangge Uppe", 
                    description: "Three floor bar, open until 5 am",
                    style: "Bar",
                    neighborhood: "Old Town")

location_table.insert(name: "Bub City", 
                    description: "Country restaurant and bar with barebeque and live music.",
                    style: "Restaurant",
                    neighborhood: "River North")
