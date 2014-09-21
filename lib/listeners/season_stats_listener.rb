require 'open-uri'
require 'nokogiri'

class SeasonStatsListener < Listener

  StatsIndices = [
    10, #FG%
    13, #3%
    19, #FT%
    22, #reb
    23, #ast
    24, #stl
    25, #blk
    26, #to
    28, #pts
  ]

  TableHeaders = ["FG%", "3P%", "FT%", "REB", "AST", "STL", "BLK", "TO", "PTS"]

  def pattern
    raise
  end

  def call(comment, match_data)
    raise
  end

  def parse_stats(doc, year = Time.now.year)
    player_name = doc.css("h1").text
    per_game = doc.xpath("//tr[@id='per_game.#{year}']")

    if per_game.any?
      teams = []
      stats = []

      per_game.each do |year|
        cells = year.css("td")
        next if cells[2].text == "TOT"
        teams << cells[2].text
        stat_line = StatsIndices.map { |i| cells[i].text }
        stats << stat_line
      end

      aliased_player_name = PlayerNames[player_name] || player_name
      stat_markdown = ["**#{aliased_player_name}**'s #{year - 1}-#{year} per game stats (w/ #{teams.join(", ")}):\n"]
      stat_markdown << "|#{TableHeaders.join("|")}|"
      stat_markdown << "|#{"----|" * TableHeaders.size}"
      stats.each do |stat_line|
        stat_markdown << "|#{stat_line[0..TableHeaders.size].join("|")}|"
      end

      stats_as_comment stat_markdown
    else
      nil
    end
  end

  def stats_as_comment(stat_markdown)
    stat_markdown.join("\n")
  end
end
