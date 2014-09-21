class LastSeasonStatsListener < SeasonStatsListener

  def pattern
    /((what|how).(were|was).(?<name>.+)(\'s)?.((last\s(season|year)\sstats)|(stats\slast\s(season|year))))/ix
  end

  def call(comment, match_data)
    search_term = match_data["name"].gsub("'s", "")

    doc = open("http://www.basketball-reference.com/search/search.fcgi?pid=&search=#{search_term.gsub(" ", "+")}").read
    doc = Nokogiri::HTML(doc)

    comment_body = if doc.css(".uni_holder").any?
      year = Time.now.month >= 9 ? Time.now.year : Time.now.year - 1
      parse_stats(doc, year)
    elsif link = doc.css(".search-item-name a").first
      player_url = link["href"]
      player_url = "http://www.basketball-reference.com#{player_url}" if player_url[0] == "/"
      player_doc = Nokogiri::HTML open(player_url).read
      parse_stats(player_doc, 2014)
    end

    send_reply(comment, comment_body)
  end

end
