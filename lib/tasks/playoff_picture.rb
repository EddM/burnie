require "open-uri"
require "nokogiri"

class PlayoffPictureTask
  DataSource = "http://espn.go.com/nba/playoffs/matchups"
  RecordRegex = /\([0-9]{1,2}\-[0-9]{1,2}(\,.\.[0-9]{3})?\)/i

  def call(client)
    @client = client

    update_sidebar(matchups)
  end

  private

  def update_sidebar(matchups)
    full_markdown = matchups_to_markdown(matchups)
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    sidebar_text.gsub!(/\#\#\[Playoff Picture(.*?)\#\#/m, "#{full_markdown}\n\n##")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
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

    ["##[Playoff Picture](#{DataSource})", table.join("\n")].join("\n\n")
  end

  def matchups
    return @matchups if @matchups

    resource = open(DataSource)
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
end
