require 'open-uri'

class SummerLeague::Core
  attr_reader :games

  URLS = [
    "https://data.nba.com/data/10s/v2015/json/mobile_teams/sacramento/2019/league/13_full_schedule.json",
    "https://data.nba.com/data/10s/v2015/json/mobile_teams/vegas/2019/league/15_full_schedule.json",
    "https://data.nba.com/data/10s/v2015/json/mobile_teams/utah/2019/league/16_full_schedule.json"
  ]

  def initialize
    @games = []

    fetch_games
  end

  private

  def fetch_games
    URLS.each do |url|
      data = JSON.parse(open(url).read)

      games = data["lscd"][0]["mscd"]["g"].select do |game|
        game["v"]["ta"] == "MIA" || game["h"]["ta"] == "MIA"
      end

      @games << games
    end

    @games.flatten!.sort_by! { |game| Time.parse game["etm"] }
  end
end
