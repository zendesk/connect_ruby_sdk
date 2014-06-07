require 'test/unit'
require 'logger'
require_relative '../lib/outbound'

class TestOutbound < Test::Unit::TestCase
  def setup
    Outbound.init "mytestkey", Logger::DEBUG
  end

  def test_identify
    result = Outbound.identify [1,2]
    assert result.user_id_error?, "Expected user ID error in identify call."
  end

  def test_track
    result = Outbound.track [1,2], "event"
    assert result.user_id_error?, "Expected user ID error in track call."

    result = Outbound.track "user id", ["event"]
    assert result.event_name_error?, "Expected event name error in track call."
  end
end
