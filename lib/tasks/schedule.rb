class ScheduleTask
  TZ = "Eastern Time (US & Canada)"
  ScheduleURL = "https://www.nba.com/heat/schedule/"
  DataSource = "https://uk.global.nba.com/stats2/team/schedule.json?countryCode=US&locale=en&teamCode=heat"
  MaxGames = 10

  def call(client, year, month, day)
    @client = client

    full_markdown = ["##[Schedule](#{ScheduleURL})", calendar_to_markdown]
                    .join("\n\n")

    update_sidebar(full_markdown)
  end

  def games
    return @games if @games
    data = open(DataSource).read
    @games = JSON.parse(data)["payload"]["monthGroups"].collect { |month_group| month_group["games"] }.flatten
  end

  private

  def calendar_to_markdown
    games.map! do |game|
      game["time"] = Time.at(game["profile"]["utcMillis"].to_i / 1000)
      game
    end

    previous_games = games.select { |game| game["time"] < Time.now }.pop(5)
    next_games = Array(games.select { |game| game["time"] >= Time.now }[0..(MaxGames - (previous_games.size + 1))])

    table = ["|Date|Matchup|Score|", "|:--:|:--:|:--:|"]

    previous_games.each do |game|
      result = if game["boxscore"]["status"].to_i >= 3
        win = game["winOrLoss"] == "Won"

        "#{"**" if win}#{game["boxscore"]["awayScore"]} - #{game["boxscore"]["homeScore"]} " \
        "#{win ? "W" : "L"}#{"**" if win}#{" *(Preseason)*" if game["profile"]["seasonType"] == "1"}"
      end

      table << "|#{format_time game["time"]}|#{opponent_line(game)}|#{result}|"
    end

    next_games.each do |game|
      if game["profile"]["seasonType"] == "1"
        status = " *(Preseason)*"
      elsif game["profile"]["seasonType"] == "4"
        status = "*Game #{game["profile"]["number"]}*"

        # if game["profile"]["statusDesc"] == "TBD"
        #   status = "#{status} *(if nec.)*"
        # end
      else
        status = ""
      end

      time = format_time game["time"], game["boxscore"]["statusDesc"] == "TBD"

      row = "|#{time}|" \
            "#{opponent_line(game)}|" \
            "#{status}|"

      table << row
    end

    table.join("\n")
  end

  def opponent_line(game)
    if game["homeTeam"]["profile"]["displayAbbr"] == "MIA"
      subreddit_link game["awayTeam"]["profile"]["displayAbbr"]
    else
      subreddit_link game["homeTeam"]["profile"]["displayAbbr"], "@ #{game["homeTeam"]["profile"]["displayAbbr"]}"
    end
  end

  def format_time(datetime, tbd = false)
    datetime = datetime.in_time_zone(TZ)
    date = datetime.strftime("%a, %b %e").strip
    time = datetime.strftime("%l:%M %p").strip

    "#{date} *#{tbd ? "TBD" : time}*"
  end

  def subreddit_link(abbreviation, label = nil)
    "[#{label || abbreviation}](/r/#{Subreddits[abbreviation]})"
  end

  def update_sidebar(full_markdown)
    subreddit = Subreddit.new(@client, Configuration["subreddit"])
    subreddit_attributes = subreddit.attributes
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#\[?Schedule(.*?)\#\#/im, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], description: sidebar_text)
  end
end
