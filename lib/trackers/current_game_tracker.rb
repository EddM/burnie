require 'active_support/all'
require 'date'
require 'open-uri'
require 'json'

class CurrentGameTracker
  attr_reader :sleep_duration
  attr_reader :started_at
  attr_reader :current_game

  DataSource = "http://nba-schedule.herokuapp.com/schedule/MIA.json"

  def initialize(client)
    @client = client
    @sleep_duration = 15
    @started_at = Time.now

    @current_game = self.games.find do |game|
      now = Time.now.in_time_zone("Eastern Time (US & Canada)") + 30.minutes # now (in ET) + 30 minutes
      game_starts_at = Time.parse(game["datetime"]).to_datetime.utc.change(:offset => "-05:00")
      game_end_threshold = game_starts_at + 6.hours

      game_starts_at.to_datetime < now.to_datetime && game_end_threshold.to_datetime > now.to_datetime
    end
  end

  def active?
    @current_game && Time.now < self.ends_at
  end

  def ends_at
    @ends_at ||= @started_at + 6.hours
  end

  def data_url
    return @data_url if @data_url

    if @current_game
      team_string = "#{@current_game["away_team"][1]}#{@current_game["home_team"][1]}"
      game_time = Time.parse(@current_game["datetime"])
      date_string = "#{game_time.year}#{game_time.month}#{game_time.day.to_s.rjust(2, '0')}"

      @data_url = "http://www.nba.com/games/#{date_string}/#{team_string}/gameinfo.html"
    end
  end

  def check
    doc = Nokogiri::HTML open(self.data_url).read
    new_away_score, new_home_score = doc.css("#nbaGIGameScore h1").collect(&:text).collect(&:to_i)

    if new_away_score != @current_game["away_score"] || new_home_score != @current_game["home_score"]
      @current_game["away_score"], @current_game["home_score"] = new_away_score, new_home_score
      @current_game["last_updated_time"] = doc.css("#nbaGITmeQtr h2, #nbaGITmeQtr p").collect(&:text).join(" ")
      puts " - Updating score... #{@current_game["away_score"]} - #{@current_game["home_score"]}"

      fetch_stat_leaders(doc)
      update_sidebar
    end
  end

  def update_sidebar
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    @original_sidebar_text ||= sidebar_text
    sidebar_text.gsub!(/######(.*)\n\n/imx, "#######{self.score_string}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

  def score_string
    markdown = ["LIVE SCORE UPDATE: " + 
    "[#{@current_game["away_team"][0]}](/r/#{Subreddits[@current_game["away_team"][1]]}) #{@current_game["away_score"]}" +
    " @ " + 
    "[#{@current_game["home_team"][0]}](/r/#{Subreddits[@current_game["home_team"][1]]}) #{@current_game["home_score"]}" +
    " ([#{@current_game["last_updated_time"]}](#{self.data_url}))"]

    stat_leaders = @current_game["leaders"].collect do |team|
      team.max_by do |player, stats|
        stats[0]
      end
    end.compact

    if stat_leaders.any?
      markdown << stat_leaders.collect do |leader| 
        "#{leader[0]} (#{leader[1][0]} PTS, #{leader[1][1]} AST, #{leader[1][2]} REB)"
      end.join(", ")
    end

    markdown.join(" | ")
  end

  def fetch_stat_leaders(doc)
    @current_game["leaders"] = []

    doc.css("#nbaGIboxscore table").each do |table|
      team_stats = {}

      table.css("tr.odd, tr.even").each do |row|
        cells = row.css("td")

        if cells.length > 2 && cells[0].text != "Total"
          points = cells.last.text.to_i
          assists = cells[10].text.to_i
          rebounds = cells[9].text.to_i

          team_stats[cells[0].text.strip] = [points, assists, rebounds] if points > 0
        end
      end

      @current_game["leaders"] << team_stats
    end
  end

  def games
    return @games if @games
    data = open(DataSource).read
    @games = JSON.parse(data)
  end

  def reset_sidebar
    if @original_sidebar_text
      @client.update_subreddit(Configuration["subreddit"], { 
        :description => @original_sidebar_text 
      })
    end
  end

  def self.track(client)
    loop do
      if @tracker && @tracker.active?
        puts " - Game is live! Checking on it..."
        @tracker.check
        sleep @tracker.sleep_duration
      else
        if @tracker
          @tracker.reset_sidebar
          @tracker = nil
        end

        puts " - Checking to see if there's a live game"
        @tracker = self.new(client)
        sleep 60
      end
    end
  end  

end
