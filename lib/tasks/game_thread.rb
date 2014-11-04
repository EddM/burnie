class GameThreadTask

  DataSource = "http://nba-schedule.herokuapp.com/schedule/MIA.json"
  PreSeasonGames = 8

  def call(client)
    @client = client
    today = Time.now

    games.each_with_index do |game, i|
      game_time = Time.parse(game["datetime"])

      if game_time.year == today.year && game_time.month == today.month && game_time.day == today.day
        puts " - Building game thread for #{game["away_team"][1]} @ #{game["home_team"][1]}"

        detail_url = "http://www.nba.com/games/#{game_time.year}#{game_time.month}#{game_time.day.to_s.rjust(2, '0')}/#{game["away_team"][1]}#{game["home_team"][1]}/gameinfo.html"
        detail = Nokogiri::HTML open(detail_url).read
        away_stats = [detail.css(".nbaGIHomeStatCat td")[2], detail.css(".nbaGIHomeStatCat td")[3]]
        home_stats = [detail.css(".nbaGIAwayStatCat td")[2], detail.css(".nbaGIAwayStatCat td")[3]]
        media = detail.css("#nbaGITvInfo tr").map do |tr|
          td = tr.css("td#nbaGIWatch").first

          if td
            td.text.strip
          elsif td = tr.css("td#nbaGITvFirst")[2]
            td.text.strip
          end
        end.compact

        title = "#{game["away_team"][0]} (#{away_stats.join("-")}) @ #{game["home_team"][0]} (#{home_stats.join("-")}) - #{game_time.month}/#{game_time.day}, #{game_time.strftime("%I:%M %p")} ET"

        body = [
          "**[#{game["away_team"][0]}](/r/#{Subreddits[game["away_team"][1]]}) @ [#{game["home_team"][0]}](/r/#{Subreddits[game["home_team"][1]]})**",
          "",
          "Regular Season, Game #{i - (PreSeasonGames - 1)}",
          "",
          "",
          "|Game Details||",
          "|:---|:---|",
          "|**Location:**|#{detail.css(".nbaGILocat").text}|",
          "|**Tip-off time:**|#{game_time.strftime("%I:%M%p")} Eastern (#{(game_time - 3600).strftime("%I:%M%p")} Central, #{(game_time - 10800).strftime("%I:%M%p")} Pacific, #{(game_time + 18000).strftime("%I:%M%p")} GMT)|",
          "|**TV/Radio:**|#{media.join(" / ")}|",
          "|**Game Info & Stats:**|[NBA.com](#{detail_url}) / [BoxScoreReplay.com](http://www.boxscorereplay.com/#{game_time.month}#{game_time.day}-#{game["away_team"][0].downcase.gsub(" ", "-")}-#{game["home_team"][0].downcase.gsub(" ", "-")})|",
          "",
          "Let's go heat!"
        ].join("\n")

        response = client.submit "[Game Thread] #{title}", Configuration["subreddit"], { text: body, extension: 'json' }
        puts " - Posted game thread"

        # client.set_sticky_post link, true
        # puts "   - Stickied"
      end
    end
  end

  def games
    return @games if @games
    data = open(DataSource).read
    @games = JSON.parse(data)
  end

end
