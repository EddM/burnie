require 'open-uri'
require 'nokogiri'

class LastSeasonStatsListener < Listener

  StatsIndices = [
    5, # GP
    7, #MP
    8, 9, 10, #FG
    11, 12, 13, #3
    17, 18, 19, #FT
    22, #reb
    23, #ast
    24, #stl
    25, #blk
    26, #to
    28, #pts
  ]

  TableHeaders = ["G", "MP", "FGM", "FGA", "FG%", "3PM", "3PA", "3P%", "FTM", "FTA", "FT%", "REB", "AST", "STL", "BLK", "TO", "PTS"]

  def pattern
    /((what|how).(were|was).(?<name>.+)(\'s)?.((last\s(season|year)\sstats)|(stats\slast\s(season|year))))/ix
  end

  def call(comment, match_data)
    search_term = match_data["name"].gsub("'s", "")

    doc = open("http://www.basketball-reference.com/search/search.fcgi?pid=&search=#{search_term.gsub(" ", "+")}").read
    doc = Nokogiri::HTML(doc)

    comment_body = if doc.css(".uni_holder").any?
      parse_stats(doc)
    elsif link = doc.css(".search-item-name a").first
      player_url = link["href"]
      player_url = "http://www.basketball-reference.com#{player_url}" if player_url[0] == "/"
      player_doc = Nokogiri::HTML open(player_url).read
      parse_stats(player_doc)
    end

    send_reply(comment, comment_body)
  end

  def parse_stats(doc)
    player_name = doc.css("h1").text
    per_game_2014 = doc.xpath("//tr[@id='per_game.2014']")

    if per_game_2014.any?
      teams = []
      stats = []

      per_game_2014.each do |year|
        cells = year.css("td")
        next if cells[2].text == "TOT"
        teams << cells[2].text
        stat_line = StatsIndices.map { |i| cells[i].text }
        stats << stat_line
      end

      aliased_player_name = PlayerNames[player_name] || player_name
      stat_markdown = ["**#{aliased_player_name}**'s 2013-14 per game stats (w/ #{teams.join(", ")}):\n"]
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
