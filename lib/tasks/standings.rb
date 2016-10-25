require "open-uri"
require "nokogiri"

class StandingsTask
  DATA_SOURCE = "http://uk.global.nba.com/stats2/season/divisionstanding.json"

  def call(client)
    @client = client

    update_sidebar(standings)
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
    table << "|Team|W|L|PCT|Form|"
    table << "|:--:|:--:|:--:|:--:|:--:|"

    standings.each do |line|
      table << "|#{line.join("|")}|"
    end

    ["##[Standings](http://espn.go.com/nba/standings/_/group/3)", table.join("\n")].join("\n\n")
  end

  def standings
    data = JSON.parse open(DATA_SOURCE).read
    division = data["payload"]["standingGroups"].find { |group| group["division"] == "Southeast" }
    teams = division["teams"].sort_by { |team| team["standings"]["divRank"] }

    teams.map do |team|
      win_pct = (team["standings"]["winPct"] / 100.0)
      is_mia = team["profile"]["displayAbbr"] == "MIA"

      [
        build_cell("[#{team["profile"]["city"]}](/r/#{Subreddits[team["profile"]["displayAbbr"]]})", is_mia),
        build_cell(team["standings"]["wins"], is_mia),
        build_cell(team["standings"]["losses"], is_mia),
        build_cell(win_pct == 1 ? "1.000" : win_pct.to_s.ljust(5, "0")[1..4], is_mia),
        build_cell(team["standings"]["streak"].gsub("Lost", "L").gsub("Won", "W"), is_mia)
      ]
    end
  end

  def build_cell(content, is_mia)
    "#{"**" if is_mia}#{content}#{"**" if is_mia}"
  end
end
