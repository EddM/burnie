class Listener
  attr_reader :client

  def initialize(client, comment)
    raise "Please provide a pattern to match in this listener" unless @@pattern

    if comment && match_data = comment["body"].match(@@pattern)
      @client = client
      call(comment, match_data)
    end
  end

  def call(comment, match_data)
    raise
  end

  def self.matches(pattern)
    @@pattern = Regexp.new(pattern)
  end

end
