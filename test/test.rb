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

  def test_disable
    result = Outbound.disable Outbound::APNS, [1,2], "token"
    assert result.user_id_error?, "Expected user ID error in disable call."

    result = Outbound.disable "SOMETHING", "user_id", "token"
    assert result.platform_error?, "Expected platform error in disable call."

    result = Outbound.disable Outbound::APNS, "user id", ["event"]
    assert result.token_error?, "Expected token error in disable call."
  end

  def test_register
    result = Outbound.register Outbound::APNS, [1,2], "token"
    assert result.user_id_error?, "Expected user ID error in register call."

    result = Outbound.register "SOMETHING", "user_id", "token"
    assert result.platform_error?, "Expected platform error in register call."

    result = Outbound.register Outbound::APNS, "user id", ["event"]
    assert result.token_error?, "Expected token error in register call."
  end
end
