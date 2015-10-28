require 'open-uri'
require 'nokogiri'

class StandingsTask

  DataSource = 'http://espn.go.com/nba/standings/_/group/division'

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
    table << "|Team|W|L|PCT|"
    table << "|:--:|:--:|:--:|:--:|"
    standings.each do |line|
      subreddit = Subreddits[Teams[line[0]]]
      line[0] = "[](/r/#{subreddit}) #{line[0]}"
      table << "|#{line.join("|")}|"
    end

    ["##[Standings](http://espn.go.com/nba/standings/_/group/3)", table.join("\n")].join("\n\n")
  end

  def standings
    return @standings if @standings

    resource = open(DataSource)
    doc = Nokogiri::HTML(resource.read)
    thead = doc.css("thead.standings-categories").select { |el| el.text =~ /southeast/i }.first
    row = thead.next_element

    @standings = []
    5.times do
      if row
        cells = row.css('td')
        team_name = cells[0].css('a')[1].text.split(" ")[0]
        wins, losses, percentage = cells[1].text, cells[2].text, cells[3].text
        @standings << [team_name, wins.to_i, losses.to_i, percentage]
        row = row.next_element
      end
    end

    @standings
  end

end
