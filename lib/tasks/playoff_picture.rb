require "open-uri"
require "nokogiri"
require "json"

class PlayoffPictureTask
  MatchupDataSource = "http://espn.go.com/nba/playoffs/matchups"
  CurrentMatchupDataSource = "http://data.nba.com/jsonp/5s/json/cms/2015/playoffs_series/series_details.json"
  RecordRegex = /\([0-9]{1,2}\-[0-9]{1,2}(\,.\.[0-9]{3})?\)/i

  def call(client)
    @client = client

    update_matchups
    update_schedule
    post_game_thread
  end

  private

  def update_schedule
    full_markdown = schedule_to_markdown(schedule)
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#Playoff Schedule(.*?)\#\#/m, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

  def update_matchups
    full_markdown = matchups_to_markdown(matchups)
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#\[Playoff Picture(.*?)\#\#/m, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

  def post_game_thread
    data = matchup_data
    today_string = Time.now.strftime("%Y%m%d")

    data["sports_content"]["round"].each do |round|
      round["conference"][0]["series"].each do |series|
        next unless series["teams"].any? { |team| team["team_key"] == "MIA" }

        series["game"].each do |game|
          if game["date"] == today_string
            game_time = Time.parse("#{game["date"]}#{game["time"]}")
            detail_url = "http://www.nba.com/games/#{game_time.year}#{game_time.month.to_s.rjust(2, '0')}#{game_time.day.to_s.rjust(2, '0')}/#{game["visitor"]["abbreviation"]}#{game["home"]["abbreviation"]}/gameinfo.html"
            media = game["broadcasters"]["tv"]["broadcaster"].collect { |b| b["display_name"] } +
                    game["broadcasters"]["radio"]["broadcaster"].collect { |b| b["display_name"] }

            body = [
              "**##{game["playoffs"]["visitor_seed"]} [#{game["visitor"]["city"]} #{game["visitor"]["nickname"]}](/r/#{Subreddits[game["visitor"]["abbreviation"]]}) (#{game["playoffs"]["visitor_wins"]}) @ " \
              "##{game["playoffs"]["home_seed"]} [#{game["home"]["city"]} #{game["home"]["nickname"]}](/r/#{Subreddits[game["home"]["abbreviation"]]}) (#{game["playoffs"]["home_wins"]})**",
              "",
              "#{round_number_to_string(game["playoffs"]["round"])}, Game #{game["playoffs"]["game_number"]}",
              "",
              "",
              "|Game Details||",
              "|:---|:---|",
              "|**Location:**|#{game["arena"]}, #{game["city"]}, #{game["state"]}|",
              "|**Tip-off time:**|#{game_time.strftime("%I:%M%p")} Eastern (#{(game_time - 3600).strftime("%I:%M%p")} Central, #{(game_time - 10800).strftime("%I:%M%p")} Pacific, #{(game_time + 18000).strftime("%I:%M%p")} GMT)|",
              "|**TV/Radio:**|#{media.join(" / ")}|",
              "|**Game Info & Stats:**|[NBA.com](#{detail_url})|",
              "",
            ].join("\n")

            title = "#{game["visitor"]["city"]} #{game["visitor"]["nickname"]} (#{game["playoffs"]["visitor_wins"]}) @ #{game["home"]["city"]} #{game["home"]["nickname"]} (#{game["playoffs"]["home_wins"]}) - #{round_number_to_string(game["playoffs"]["round"])}, Game #{game["playoffs"]["game_number"]} - #{game_time.month}/#{game_time.day}, #{game_time.strftime("%I:%M %p")} ET"

            response = @client.submit "[Game Thread] #{title}", Configuration["subreddit"], { text: body, extension: 'json' }
          end
        end
      end
    end
  end

  def round_number_to_string(number)
    case number.to_i
    when 1
      "First Round"
    when 2
      "Semi-Finals"
    when 3
      "Conference Finals"
    when 4
      "Finals"
    end
  end

  def schedule_to_markdown(schedule)
    markdown = []
    teams = schedule["teams"].map do |team|
      "**[#{team["city"]} #{team["nickname"]} (#{team["wins"]})](/r/#{Subreddits[team["team_key"]]})**"
    end

    markdown << "#{teams.join("\n\nvs.\n\n")}"
    markdown << ""

    schedule["game"].each do |game|
      date = Time.parse("#{game["date"]} #{game["time"]}")

      game_string = "**Game #{game["playoffs"]["game_number"]}#{" (*)" if game["playoffs"]["game_necessary_flag"] == "1"}**"
      time_string = date.strftime("%b %e, %I:%M %p")
      location = "#{game["city"]}, #{game["state"]}"

      if game["playoffs"]["game_necessary_flag"] == "1"
        score_string = "*(If necc.)*"
      elsif game["playoffs"]["gameStatus"] == "3"
        visitor_score = game["visitor"]["score"].to_i
        home_score = game["home"]["score"].to_i

        if ((visitor_score > home_score) && game["visitor"]["team_key"] == "MIA") ||
          ((home_score > visitor_score) && game["home"]["team_key"] == "MIA")
          result = "W"
        else
          result = "L"
        end

        score_string = "(#{visitor_score} - #{home_score} **#{result}**)"
      else
        score_string = ""
      end

      markdown << ["#{game["playoffs"]["game_number"]}. #{game_string}",
                   "    ",
                   "    #{time_string}, #{location} #{score_string}"].join("\n")
    end

    "##Playoff Schedule\n\n#{markdown.join("\n")}"
  end

  def matchups_to_markdown(matchups)
    table = []
    table << "|R1|R2|ECF|"
    table << "|:--:|:--:|:--:|"
    matchups.each_with_index do |matchup, i|
      team1 = matchup[0].gsub(/(\([0-9]\).)|.#{RecordRegex}/, "")
      team2 = matchup[1].gsub(/(\([0-9]\).)|.#{RecordRegex}/, "")
      subreddits = [Subreddits[Teams[team1]], Subreddits[Teams[team2]]]
      table << "|*[](/r/#{subreddits[0]}) #{matchup[0]}* *[](/r/#{subreddits[1]}) #{matchup[1]}*|-|#{"-" if i == 1 || i == 2}|"
    end

    ["##[Playoff Picture](#{MatchupDataSource})", table.join("\n")].join("\n\n")
  end

  def matchups
    return @matchups if @matchups

    resource = open(MatchupDataSource)
    doc = Nokogiri::HTML(resource.read)
    table = doc.css(".col-main table").first

    table.css("tr.colhead").map do |row|
      [row.next_element, row.next_element.next_element].map do |element|
        record = element.css("td").last.inner_html.split("<br>").first[RecordRegex]
        wins, losses = record.gsub(/\(|\)/, "").split("-").map(&:to_i)
        record = "(#{wins}-#{losses}, #{(wins.to_f / (wins + losses)).round(3).to_s.gsub(/^0/, "")})"
        "#{element.css("strong").text} `#{record}`"
      end
    end
  end

  def schedule
    data = matchup_data

    data["sports_content"]["round"].each do |round|
      next if round["completed"] != ""

      round["conference"][0]["series"].each do |series|
        return series if series["teams"].any? { |team| team["team_key"] == "MIA" }
      end
    end
  end

  def matchup_data
    @matchup_data ||= JSON.parse(open(CurrentMatchupDataSource).read.gsub(/callbackWrapper\(|\)\;/, ""))
  end
end
