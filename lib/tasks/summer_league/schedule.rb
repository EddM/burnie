class SummerLeague::ScheduleTask
  SCHEDULE_URL = "http://stats.nba.com/schedule/summerleague/#!/?rfr=nba"
  TZ = "Eastern Time (US & Canada)"

  def call(client)
    @client = client
    @schedule = []
    @core = SummerLeague::Core.new
    @games = @core.games

    build_schedule
    update_sidebar
  end

  private

  def build_schedule
    @schedule << "##[Schedule](#{SCHEDULE_URL})"
    @schedule << "|Date|Matchup|Score|"
    @schedule << "|:--:|:--:|:--:|"
    now = Time.now

    @games.map do |game|
      time = Time.parse "#{game["etm"]} EST"

      if time < Time.now && game["v"]["s"] && game["h"]["s"]
        home_score = game["h"]["s"].to_i
        away_score = game["v"]["s"].to_i
        is_home = game["h"]["ta"] == "MIA"

        if (is_home && home_score > away_score) || (!is_home && away_score > home_score)
          result = "W"
        else
          result = "L"
        end

        row = "|#{format_time time}|" \
              "#{opponent_line(game)}|" \
              "#{"**" if result == "W"}#{away_score} - #{home_score} #{result}#{"**" if result == "W"}|"
      else
        row = "|#{format_time time}|" \
              "#{opponent_line(game)}|" \
              "|"
      end

      @schedule << row
    end
  end

  def format_time(datetime)
    datetime = datetime.in_time_zone(TZ) - 1.hour
    date = datetime.strftime("%a, %b %e").strip
    time = datetime.strftime("%l:%M %p").strip

    "#{date} *#{time}*"
  end

  def opponent_line(game)
    if game["h"]["ta"] == "MIA"
      subreddit_link game["v"]["ta"]
    else
      subreddit_link game["h"]["ta"], "@ #{game["h"]["ta"]}"
    end
  end

  def subreddit_link(abbreviation, label = nil)
    "[#{label || abbreviation}](/r/#{Subreddits[abbreviation]})"
  end

  def update_sidebar
    full_markdown = @schedule.join("\n")
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#\[?Schedule(.*?)\#\#/im, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], description: sidebar_text)
  end
end
