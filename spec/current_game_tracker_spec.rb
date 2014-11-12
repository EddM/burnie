require 'spec_helper'

describe CurrentGameTracker do

  before :each do
    @client = double
  end

  it "should detect when there's a game live" do
    Time.stub(:now).and_return Time.parse("Nov 12 2014 19:45")
    tracker = CurrentGameTracker.new(@client)
    tracker.current_game.should_not be_nil
    tracker.current_game["id"].should == 5283
    tracker.should be_active

    Time.stub(:now).and_return Time.parse("Nov 12 2014 23:30")
    tracker = CurrentGameTracker.new(@client)
    tracker.current_game.should_not be_nil
    tracker.current_game["id"].should == 5283
  end

  it "should detect when there's a game about to be live" do
    Time.stub(:now).and_return Time.parse("Nov 12 2014 19:15")
    tracker = CurrentGameTracker.new(@client)
    tracker.current_game.should_not be_nil
    tracker.current_game["id"].should == 5283
  end

  it "shouldn't detect a game as live when there isn't one" do
    Time.stub(:now).and_return Time.parse("Nov 12 2014 18:00")
    tracker = CurrentGameTracker.new(@client)
    tracker.current_game.should be_nil

    Time.stub(:now).and_return Time.parse("Nov 13 2014 03:00")
    tracker = CurrentGameTracker.new(@client)
    tracker.current_game.should be_nil
  end

  it "should generate a good data url" do
    Time.stub(:now).and_return Time.parse("Nov 12 2014 19:45")
    tracker = CurrentGameTracker.new(@client)
    tracker.data_url.should == "http://www.nba.com/games/20141112/INDMIA/gameinfo.html"
  end

end
