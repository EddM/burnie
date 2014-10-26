require 'open-uri'
require 'json'

require './lib/listener.rb'
require './lib/listeners/about_me_listener.rb'
require './lib/listeners/career_stats_listener.rb'
require './lib/listeners/season_stats_listener.rb'
require './lib/listeners/season_listeners/last_season_stats_listener.rb'
require './lib/listeners/season_listeners/current_season_stats_listener.rb'

class PrimaryListener

  SleepTimePerCycle = 10

  def initialize(client)
    @client = client
    @most_recent_comment = Time.now - 300
    @listeners = [LastSeasonStatsListener, CurrentSeasonStatsListener, CareerStatsListener, AboutMeListener]

    loop do
      @first_comment = nil

      begin
        comments = JSON.parse open(url).read
        sleep(5)

        comments["data"]["children"].each do |comment|
          comment = comment["data"]
          @first_comment = comment unless @first_comment
          comment_created_at = Time.at(comment["created"]) - 28800
          break if comment_created_at <= @most_recent_comment

          if comment["author"] == Configuration["username"]
            puts " - Ignoring comment #{comment["id"]} by #{comment["author"]}"
            next
          end

          puts " - Processing comment #{comment["id"]} by #{comment["author"]}"

          @listeners.each do |klass|
            begin
              klass.new(@client, comment)
            rescue => e
              puts "  - Exception occured during #{klass}:"
              puts "      #{e}"
              puts "      #{e.backtrace.join("\n      ")}"
            end
          end
        end

        @most_recent_comment = Time.at(@first_comment["created"]) - 28800 if @first_comment
      rescue RedditKit::RateLimited
        puts " - Rate limited. Waiting..."
      end

      @first_comment = nil
      sleep(SleepTimePerCycle - 5)
    end
  end

  def self.listen(client)
    listener = self.new(client)
  end

  private

  def url
    @url ||= "http://www.reddit.com/r/#{Configuration["subreddit"]}/comments.json"
  end

end
