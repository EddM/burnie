class SummerLeague::GameThreadTask
  def call(client)
    @client = client
    data = JSON.parse(open(data_source).read)

    data["sports_content"]["games"]["game"].each do |game|
      post_game_thread(game) if game["visitor"]["team_key"] == "MIA" || game["home"]["team_key"] == "MIA"
    end
  end

  def data_source
    today = Time.now
    date_string = "#{today.year}#{today.month.to_s.rjust(2, "0")}#{today.day.to_s.rjust(2, "0")}"

    "http://data.nba.com/data/5s/json/cms/noseason/scoreboard/#{date_string}/games.json"
  end

  private

  def post_game_thread(game)
    game_time = Time.parse("#{game["date"]}#{game["time"]}")
    detail_url = "http://www.nba.com/games/#{game_time.year}#{game_time.month.to_s.rjust(2, '0')}#{game_time.day.to_s.rjust(2, '0')}/#{game["visitor"]["abbreviation"]}#{game["home"]["abbreviation"]}/gameinfo.html"
    title = "#{game["visitor"]["city"]} #{game["visitor"]["nickname"]} @ #{game["home"]["city"]} #{game["home"]["nickname"]} - Summer League - #{game_time.month}/#{game_time.day}, #{game_time.strftime("%I:%M %p")} ET"

    media = game["broadcasters"]["tv"]["broadcaster"].collect { |b| b["display_name"] }

    body = [
      "**[#{game["visitor"]["city"]} #{game["visitor"]["nickname"]}](/r/#{Subreddits[game["visitor"]["abbreviation"]]}) @ " \
      "[#{game["home"]["city"]} #{game["home"]["nickname"]}](/r/#{Subreddits[game["home"]["abbreviation"]]})**",
      "",
      "[#{Time.now.year} Summer League](http://www.nba.com/summerleague) (#{game["city"]})",
      "",
      "",
      "|Game Details||",
      "|:---|:---|",
      "|**Location:**|#{game["arena"]}, #{game["city"]}, #{game["state"]}|",
      "|**Tip-off time:**|#{game_time.strftime("%I:%M%p")} Eastern (#{(game_time - 3600).strftime("%I:%M%p")} Central, #{(game_time - 10800).strftime("%I:%M%p")} Pacific, #{(game_time + 18000).strftime("%I:%M%p")} GMT)|",
      "|**TV/Radio:**|#{media.join(" / ")} / League Pass|",
      "|**Game Info & Stats:**|[NBA.com](#{detail_url})|",
      "|**Important info:**|[Miami Heat Summer League Rosters](http://basketball.realgm.com/nba/teams/Miami-Heat/15/Rosters/Summer_League/#{Time.now.year})|",
    ].join("\n")

    response = @client.submit "[Game Thread] #{title}", Configuration["subreddit"], { text: body, extension: "json" }
  end
end
