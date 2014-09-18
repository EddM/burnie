class ScheduleTask

  DataSource = "http://nba-schedule.herokuapp.com/schedule/MIA.json"
  StartOfSeason = [10, 28]

  def call(client, year, month, day)
    @client = client

    calendar = fetch(year, month, day)
    table_markdown = calendar_to_markdown(calendar[0])
    full_markdown = ["##[#{calendar[1].to_datetime.strftime("%B")} Schedule](http://nba-schedule.herokuapp.com/schedule/MIA.html)", table_markdown].join("\n\n")
    update_sidebar(full_markdown)
  end

  def games
    return @games if @games
    data = open(DataSource).read
    @games = JSON.parse(data)
  end

  private

  def calendar_to_markdown(calendar)
    table = []
    table << "|#{calendar[0].join("|")}|"
    table << "|:--:|:--:|:--:|:--:|:--:|:--:|:--:|"
    calendar[1..-1].each do |week|
      line = week.map do |day|
        if day
          if day[1]
            char, team = day[1]
            team_subreddit = Subreddits[team]
            "^^#{day[0].day} [#{char if char == "@"}#{team}](/r/#{team_subreddit || "NBA"} \"#{"(Preseason)" if day[0].month <= StartOfSeason[0] && day[0].day <= StartOfSeason[1]} #{day[0].strftime("%R")} ET\")"
          else
            "^^#{day[0].day}"
          end
        end
      end.join("|")

      table << "|#{line}|"
    end

    table.join("\n")
  end

  def update_sidebar(full_markdown)
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#(.*?)Schedule(.*?)\#\#/imx, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

  def date_range(year, month)
    [Date.civil(year, month, 1).to_datetime, Date.civil(year, month, -1).to_datetime]
  end

  def fetch(year, month, day)
    start_of_month, end_of_month = date_range(year, month)

    games = self.games.select do |game|
      game_starts_at = Time.parse(game["datetime"]).to_datetime
      game_starts_at > start_of_month && game_starts_at < end_of_month
    end

    days_of_month = (start_of_month..end_of_month).map do |day|
      game = games.find do |game|
        game_starts_at = Time.parse(game["datetime"]).to_datetime
        game_starts_at.day == day.day
      end

      { day: day, game: game }
    end

    [calendar(days_of_month), start_of_month, end_of_month]
  end

  def week_headers
    ["M", "T", "W", "T", "F", "S", "S"]
  end

  def blank_week
    [nil] * 7
  end

  def calendar(days_of_month)
    week = blank_week
    calendar = [week_headers]

    days_of_month.each_with_index.map do |calendar_day, index|
      cursor = calendar_day[:day].cwday - 1

      if game = calendar_day[:game]
        value = [Time.parse(game["datetime"]).to_datetime]
        home_game = !!(game["home_team"].first =~ /miami heat/i)

        if home_game
          value[1] = ["v", game["away_team"].last]
        else
          value[1] = ["@", game["home_team"].last]
        end
      else
        value = [calendar_day[:day]]
      end

      week[cursor] = value

      if cursor >= 6 || index == (days_of_month.size - 1)
        calendar << week
        week = blank_week
      end
    end

    calendar
  end

end
