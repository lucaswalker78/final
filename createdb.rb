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
  String :neighborhood
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :location_id
  Boolean :worth going to
  String :name
  String :comments, text: true
end

# Insert initial (seed) data
location_table = DB.from(:location)

location_table.insert(name: "Hangge Uppe", 
                    description: "Three Floor bar open until 5 am",
                    neighborhood: "Old Town")

location_table.insert(title: "Bub City", 
                    description: "Country bar with barebeque and live music.",
                    neighborhood: "River North")
