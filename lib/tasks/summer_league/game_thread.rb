class SummerLeague::GameThreadTask
  def call(client)
    @client = client
    @core = SummerLeague::Core.new
    @games = @core.games

    todays_game = @games.find do |game|
      time = Time.parse game["etm"]
      time >= Time.now && time <= (Time.now + 86_400)
    end

    post_game_thread(todays_game) if todays_game
  end

  private

  def post_game_thread(game)
    game_time = Time.parse(game["etm"])

    title = "#{game["v"]["tc"]} #{game["v"]["tn"]} (#{game["v"]["re"]}) @ " \
            "#{game["h"]["tc"]} #{game["h"]["tn"]} (#{game["h"]["re"]}) " \
            "- Summer League - #{game_time.month}/#{game_time.day}, #{game_time.strftime("%I:%M %p")} ET"

    media = game["bd"]["b"].collect { |b| b["disp"] }

    body = [
      "**[#{game["v"]["tc"]} #{game["v"]["tn"]}](/r/#{Subreddits[game["v"]["ta"]]}) (#{game["v"]["re"]}) @ " \
      "[#{game["h"]["tc"]} #{game["h"]["tn"]}](/r/#{Subreddits[game["h"]["ta"]]}) (#{game["h"]["re"]})**",
      "",
      "[#{Time.now.year} Summer League](http://www.nba.com/summerleague) (#{game["ac"]})",
      "",
      "",
      "|Game Details||",
      "|:---|:---|",
      "|**Location:**|#{game["an"]}, #{game["ac"]}, #{game["as"]}|",
      "|**Tip-off time:**|#{game_time.strftime("%I:%M%p")} Eastern (#{(game_time - 3600).strftime("%I:%M%p")} Central, #{(game_time - 10800).strftime("%I:%M%p")} Pacific, #{(game_time + 18000).strftime("%I:%M%p")} GMT)|",
      "|**TV/Radio:**|#{media.join(" / ")} / League Pass|",
      "|**Important info:**|[Miami Heat Summer League Rosters](http://www.nba.com/magic/summer-league/rosters#heat)|",
    ].join("\n")
puts body
    # response = @client.submit "[Game Thread] #{title}", Configuration["subreddit"], { text: body, extension: "json" }
  end
end
