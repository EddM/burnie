class ScheduleTask
  DataSource = "http://nba-schedule.herokuapp.com/schedule/MIA.json"

  def call(year, month, day)
    calendar = fetch(year, month, day)
  end

  private

  def games
    return @games if @games
    data = open(DataSource).read
    @games = JSON.parse(data)
  end
  
  def fetch(year, month, day)
    start_of_month = Date.civil(year, month, 1).to_datetime
    end_of_month = Date.civil(year, month, -1).to_datetime

    games = self.games.select do |game|
      game_starts_at = Time.parse(game["datetime"]).to_datetime
      game_starts_at > start_of_month && game_starts_at < end_of_month
    end

    calendar = (start_of_month..end_of_month).map do |day|
      game = games.find do |game|
        game_starts_at = Time.parse(game["datetime"]).to_datetime
        game_starts_at.day == day.day
      end

      { day: day, game: game }
    end

    week = blank_week
    new_calendar = [week_headers]

    calendar.each_with_index do |calendar_day, index|
      cursor = calendar_day[:day].cwday - 1
      if game = calendar_day[:game]
        home_game = !!(game["home_team"].first =~ /miami heat/i)

        if home_game
          week[cursor] = "v #{game["away_team"].last}"
        else
          week[cursor] = "@ #{game["home_team"].last}"
        end
      end

      if cursor >= 6 || index == (calendar.size - 1)
        new_calendar << week
        week = blank_week
      end
    end
  end

  def week_headers
    ["M", "T", "W", "T", "F", "S", "S"]
  end

  def blank_week
    [nil] * 7
  end

end
