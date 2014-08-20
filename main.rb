require 'json'
require 'open-uri'
require 'redditkit'

require './support/redditkit_extensions.rb'

require './lib/configuration.rb'
require './lib/subreddits.rb'
require './lib/tasks/schedule.rb'

client = RedditKit::Client.new 
client.user_agent = "Burnie (/r/Heat) 1.0"
client.sign_in Configuration["username"], Configuration["password"]

if client.signed_in?
  begin
    if ARGV[0] == "schedule"
      task = ScheduleTask.new
      task.call(client, Time.now.year, 11, Time.now.day)
    end
  ensure
    client.sign_out
  end
else
  puts "Failed auth"
end
