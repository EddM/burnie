require "open-uri"
require "nokogiri"

class StandingsTask
  DIVISION_DATA_SOURCE = "http://uk.global.nba.com/stats2/season/divisionstanding.json"
  CONFERENCE_DATA_SOURCE = "http://data.nba.net/data/10s/prod/v1/current/standings_conference.json"

  def call(client)
    @client = client

    # update_sidebar(division_standings)
    update_sidebar(conference_standings)
  end

  private

  def update_sidebar(standings)
    full_markdown = standings_to_markdown(standings)
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#\[?Standings(.*?)\#\#/m, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

  def standings_to_markdown(standings)
    table = []
    table << "||Team|W|L|PCT|"
    table << "|:--:|:--|:--:|:--:|:--:|"

    standings.each do |line|
      table << "|#{line.join("|")}|"
    end

    ["##[Standings](http://espn.go.com/nba/standings/_/group/3)", table.join("\n")].join("\n\n")
  end

  def conference_standings
    data = JSON.parse open(CONFERENCE_DATA_SOURCE).read
    division = data["league"]["standard"]["conference"]["east"]
    teams = division.sort_by { |team| team["confRank"].to_i }

    teams.map do |team|
      team_profile = team_data[team["teamId"]]
      win_pct = team["winPct"]
      is_mia = team_profile["tricode"] == "MIA"

      [
        build_cell(team["confRank"], is_mia),
        build_cell("[#{team_profile["city"]}](/r/#{Subreddits[team_profile["tricode"]]})", is_mia),
        build_cell(team["win"].to_i, is_mia),
        build_cell(team["loss"].to_i, is_mia),
        build_cell(win_pct, is_mia)
      ]
    end
  end

  def division_standings
    data = JSON.parse open(DIVISION_DATA_SOURCE).read
    division = data["payload"]["standingGroups"].find { |group| group["division"] == "Southeast" }
    teams = division["teams"].sort_by { |team| team["standings"]["divRank"] }

    teams.map do |team|
      win_pct = (team["standings"]["winPct"] / 100.0)
      streak = team["standings"]["streak"].gsub("Lost ", "L").gsub("Won ", "W")
      is_mia = team["profile"]["displayAbbr"] == "MIA"

      [
        build_cell("[#{team["profile"]["city"]}](/r/#{Subreddits[team["profile"]["displayAbbr"]]})", is_mia),
        build_cell(team["standings"]["wins"], is_mia),
        build_cell(team["standings"]["losses"], is_mia),
        build_cell("#{win_pct == 1 ? "1.000" : win_pct.to_s.ljust(5, "0")[1..4]}", is_mia),
        build_cell(streak, is_mia),
      ]
    end
  end

  def build_cell(content, is_mia)
    "#{"**" if is_mia}#{content}#{"**" if is_mia}"
  end

  def team_data
    @team_data ||= begin
      data_source = "http://data.nba.net/data/10s/prod/v1/2016/teams.json"
      data = JSON.parse(open(data_source).read)
      teams = data["league"]["standard"]
      Hash[*teams.collect { |team| [team_datum_key(team), team] }.flatten]
    end
  end

  def team_datum_key(team_data)
    team_data["teamId"]
  end
end
