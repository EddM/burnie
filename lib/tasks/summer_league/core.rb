class SummerLeague::Core
  attr_reader :games

  URLS = [
    "http://data.nba.com/data/10s/v2015/json/mobile_teams/orlando/2017/league/14_full_schedule.json",
    "http://data.nba.com/data/10s/v2015/json/mobile_teams/vegas/2017/league/15_full_schedule.json"
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
