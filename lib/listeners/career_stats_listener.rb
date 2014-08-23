class CareerStatsListener < Listener

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
    /(((what|how)\sare)\s(?<name>.+)(\'s)?\scareer.stats)/ix
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
    career_totals = doc.css('#all_per_game tr.stat_total')[0]

    if career_totals
      cells = career_totals.css("td")
      stat_line = StatsIndices.map { |i| cells[i].text }

      stat_markdown = ["**#{player_name}**'s career stats:\n"]
      stat_markdown << "|#{TableHeaders.join("|")}|"
      stat_markdown << "|#{"----|" * TableHeaders.size}"
      stat_markdown << "|#{stat_line[0..TableHeaders.size].join("|")}|"

      stats_as_comment stat_markdown
    else
      nil
    end
  end

  def stats_as_comment(stat_markdown)
    stat_markdown.join("\n")
  end

end
