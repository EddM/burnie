class GameThreadTask
  TZ = "Eastern Time (US & Canada)"

  def call(client)
    @client = client
    data = JSON.parse(open(data_source).read)

    data["games"].each do |game|
      post_game_thread(game) if game["vTeam"]["triCode"] == "MIA" || game["hTeam"]["triCode"] == "MIA"
    end
  end

  def data_source
    today = Time.now
    date_string = "#{today.year}#{today.month.to_s.rjust(2, "0")}#{today.day.to_s.rjust(2, "0")}"

    "http://data.nba.net/data/10s/prod/v1/#{date_string}/scoreboard.json"
  end

  private

  def team_data
    @team_data ||= begin
      data_source = "http://data.nba.net/data/10s/prod/v1/2016/teams.json"
      data = JSON.parse(open(data_source).read)
      teams = data["league"]["standard"]
      Hash[*teams.collect { |team| [team_datum_key(team), team] }.flatten]
    end
  end

  def team_datum_key(team_data)
    team_data["tricode"]
  end

  def post_game_thread(game)
    game_time = Time.parse("#{game["startTimeUTC"]}").in_time_zone(TZ)
    detail_url = "http://www.nba.com/games/#{game_time.year}#{game_time.month.to_s.rjust(2, '0')}#{game_time.day.to_s.rjust(2, '0')}/#{game["vTeam"]["triCode"]}#{game["hTeam"]["triCode"]}"

    visitor_team = team_data[game["vTeam"]["triCode"]]
    home_team = team_data[game["hTeam"]["triCode"]]
    title = "#{visitor_team["city"]} #{visitor_team["nickname"]} (#{game["vTeam"]["win"]}-#{game["vTeam"]["loss"]}) " \
            "@ " \
            "#{home_team["city"]} #{home_team["nickname"]} (#{game["hTeam"]["win"]}-#{game["hTeam"]["loss"]}) - " \
            "#{"Preseason - " if game["seasonStageId"] == 1}" \
            "#{game_time.month}/#{game_time.day}, #{game_time.strftime("%I:%M %p")} ET"

    media = game["watch"]["broadcast"]["broadcasters"]["national"] +
            game["watch"]["broadcast"]["broadcasters"]["vTeam"] +
            game["watch"]["broadcast"]["broadcasters"]["hTeam"]

    broadcasters = media.collect { |broadcaster| broadcaster["longName"] }
    arena = Arenas[home_team["tricode"]].join(", ")

    body = [
      "**" \
      "[#{visitor_team["city"]} #{visitor_team["nickname"]}](/r/#{Subreddits[visitor_team["tricode"]]}) " \
      "(#{game["vTeam"]["win"]}-#{game["vTeam"]["loss"]})" \
      " @ " \
      "[#{home_team["city"]} #{home_team["nickname"]}](/r/#{Subreddits[home_team["tricode"]]}) " \
      "(#{game["hTeam"]["win"]}-#{game["hTeam"]["loss"]})" \
      "**",
      ("\nPreseason" if game["seasonStageId"] == 1),
      "",
      "|Game Details||",
      "|:---|:---|",
      "|**Location:**|#{arena}|",
      "|**Tip-off time:**|#{game_time.strftime("%I:%M%p")} Eastern (#{(game_time - 3600).strftime("%I:%M%p")} Central, #{(game_time - 10800).strftime("%I:%M%p")} Pacific, #{(game_time + 18000).strftime("%I:%M%p")} GMT)|",
      "|**TV/Radio:**|#{broadcasters.join(" / ")} / League Pass|",
      "|**Game Info & Stats:**|[NBA.com](#{detail_url})|",
    ].compact.join("\n")

    response = @client.submit "[Game Thread] #{title}", Configuration["subreddit"], { text: body, extension: "json" }
  end
end
