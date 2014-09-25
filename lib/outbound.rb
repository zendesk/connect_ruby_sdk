require 'logger'
require 'json'
require 'net/http'
require 'uri'

module Outbound
  VERSION = '0.3'
  BASE_URL = 'https://api.outbound.io/v2'

  APNS = "apns"
  GCM = "gcm"

  ERROR_USER_ID = "User ID must be a string or number."
  ERROR_EVENT_NAME = "Event name must be a string."
  ERROR_CONNECTION = "Outbound connection error"
  ERROR_INIT = "Must call init() before identify() or track()."
  ERROR_TOKEN = "Token must be a string."
  ERROR_PLATFORM = "Unsupported platform specified."

  @ob = nil
  @logger = Logger.new $stdout
  @logger.progname = "Outbound"
  @logger.level = Logger::ERROR

  module Defaults
    HEADERS = {
      'Content-type' => 'application/json',
      'X-Outbound-Client' => 'Ruby/' + Outbound::VERSION,
    }
  end

  def Outbound.init api_key, log_level=Logger::ERROR
    @logger.level = log_level
    @ob = Outbound::Client.new api_key, @logger
  end

  def Outbound.identify user_id, info={}, attributes={}
    if @ob == nil
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end

    return @ob.identify user_id, info, attributes
  end

  def Outbound.track user_id, event, properties={}, user_info={}, user_attributes={}
    if @ob == nil
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    return @ob.track user_id, event, properties, user_info, user_attributes
  end

  def Outbound.disable platform, user_id, token
    if @ob == nil
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    return @ob.disable platform, user_id, token
  end

  def Outbound.register platform, user_id, token
    if @ob == nil
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    return @ob.register platform, user_id, token
  end

  class Result
    include Defaults

    def initialize error, received_call
      @error = error
      @received_call = received_call
    end

    attr_accessor :error
    attr_accessor :received_call

    def success?
      return @received_call && @error == nil
    end

    def user_id_error?
      return @error == Outbound::ERROR_USER_ID
    end

    def event_name_error?
      return @error == Outbound::ERROR_EVENT_NAME
    end

    def connection_error?
      return @error == Outbound::ERROR_CONNECTION
    end

    def init_error?
      return @error == Outbound::ERROR_INIT
    end

    def token_error?
      return @error == Outbound::ERROR_TOKEN
    end

    def platform_error?
      return @error == Outbound::ERROR_PLATFORM
    end
  end

  class Client
    include Defaults

    def initialize api_key, logger
      @api_key = api_key
      @logger = logger
    end

    def identify user_id, info={}, attributes={}
      unless user_id.is_a? String or user_id.is_a? Numeric
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      user_data = {:user_id => user_id}
      begin
        user = user(info, attributes)
        user_data = user_data.merge user
      rescue
        @logger.error "Could not use user info (#{info}) and/or user attributes #{attributes} given to identify call."
      end

      return post(@api_key, '/identify', user_data)
    end

    def track user_id, event, properties={}, user_info={}, user_attributes={}
      unless user_id.is_a? String or user_id.is_a? Numeric
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless event.is_a? String
        res = Result.new Outbound::ERROR_EVENT_NAME, false
        @logger.error res.error
        return res
      end

      data = {:user_id => user_id, :event => event}

      begin
        user = user(user_info, user_attributes)
        if user.length > 0
          data[:user] = user
        end
      rescue
        @logger.error "Could not use user info (#{user_info}) and/or user attributes #{user_attributes} given to track call."
      end

      if properties.is_a? Hash
        if properties.length > 0
          data[:properties] = properties
        end
      else
        @logger.error "Could not use event properties (#{properties}) given to track call."
      end

      return post(@api_key, '/track', data)
    end

    def disable platform, user_id, token
      unless user_id.is_a? String or user_id.is_a? Numeric
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless token.is_a? String
        res = Result.new Outbound::ERROR_TOKEN, false
        @logger.error res.error
        return res
      end

      unless [Outbound::APNS, Outbound::GCM].include? platform
        res = Result.new Outbound::ERROR_PLATFORM, false
        @logger.error res.error
        return res
      end

      return post(@api_key, "/#{platform}/disable", {:token => token, :user_id => user_id})
    end

    def register platform, user_id, token
      unless user_id.is_a? String or user_id.is_a? Numeric
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless token.is_a? String
        res = Result.new Outbound::ERROR_TOKEN, false
        @logger.error res.error
        return res
      end

      unless [Outbound::APNS, Outbound::GCM].include? platform
        res = Result.new Outbound::ERROR_PLATFORM, false
        @logger.error res.error
        return res
      end

      return post(@api_key, "/#{platform}/register", {:token => token, :user_id => user_id})
    end

    private

    def post api_key, path, data
      begin
        headers = HEADERS
        headers['X-Outbound-Key'] = api_key
        payload = JSON.generate data
        uri = URI("#{BASE_URL}#{path}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        res = http.post(uri.path, payload, headers)

        status = res.code.to_i
      rescue Exception => e
        res = Result.new Outbound::ERROR_CONNECTION, false
        @logger.error res.error
        return res
      end

      err = nil
      if status < 200 or status >= 400
        err = "#{status} - #{res.body}" if res.response_body_permitted? else nil
      end
      return err, true
    end

    def user info={}, attributes={}
      unless info.is_a? Hash and attributes.is_a? Hash
        raise
      end

      user = {
        :first_name => info[:first_name],
        :last_name => info[:last_name],
        :email => info[:email],
        :phone_number => info[:phone_number],
        :apns_tokens => info[:apns_tokens],
        :gcm_tokens => info[:gcm_tokens],
        :attributes => attributes,
      }
      return user.delete_if { |k, v| v.nil? || v.empty? }
    end
  end
end
