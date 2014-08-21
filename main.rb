require 'json'
require 'open-uri'
require 'redditkit'

require './support/redditkit_extensions.rb'

require './lib/configuration.rb'
require './lib/subreddits.rb'
require './lib/teams.rb'
require './lib/tasks/schedule.rb'
require './lib/tasks/standings.rb'

client = RedditKit::Client.new 
client.user_agent = "Burnie (/r/Heat) 1.0"
client.sign_in Configuration["username"], Configuration["password"]

if client.signed_in?
  begin
    case ARGV[0]
    when "schedule"
      task = ScheduleTask.new
      task.call(client, Time.now.year, 11, Time.now.day)
    when "standings"
      task = StandingsTask.new
      task.call(client)
    end
  ensure
    client.sign_out
  end
else
  puts "Failed auth"
end
