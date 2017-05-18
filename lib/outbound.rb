require 'logger'
require 'json'
require 'net/http'
require 'uri'

module Outbound
  VERSION = '1.2.0'.freeze
  BASE_URL = 'https://api.outbound.io/v2'.freeze

  APNS = 'apns'.freeze
  GCM = 'gcm'.freeze

  ERROR_USER_ID = 'User ID must be a string or number.'.freeze
  ERROR_PREVIOUS_ID = 'Previous ID must be a string or number.'.freeze
  ERROR_EVENT_NAME = 'Event name must be a string.'.freeze
  ERROR_CONNECTION = 'Outbound connection error'.freeze
  ERROR_INIT = 'Must call init() before identify() or track().'.freeze
  ERROR_TOKEN = 'Token must be a string.'.freeze
  ERROR_PLATFORM = 'Unsupported platform specified.'.freeze
  ERROR_CAMPAIGN_IDS = 'At least one campaign ID is required.'.freeze

  @ob = nil
  @logger = Logger.new $stdout
  @logger.progname = 'Outbound'
  @logger.level = Logger::ERROR

  module Defaults
    HEADERS = {
      'Content-type' => 'application/json',
      'X-Outbound-Client' => 'Ruby/' + Outbound::VERSION
    }.freeze
  end

  def self.init(api_key, log_level = Logger::ERROR, base_url: BASE_URL)
    @logger.level = log_level
    @ob = Outbound::Client.new api_key, @logger, base_url: base_url
  end

  def self.alias(user_id, previous_id)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.identify(user_id, previous_id)
  end

  def self.identify(user_id, info = {})
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.identify(user_id, info)
  end

  def self.track(user_id, event, properties = {}, timestamp = Time.now.to_i)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.track(user_id, event, properties, timestamp)
  end

  def self.disable(platform, user_id, token)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.disable(platform, user_id, token)
  end

  def self.disable_all(platform, user_id)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.disable_all(platform, user_id)
  end

  def self.register(platform, user_id, token)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.register(platform, user_id, token)
  end

  def self.unsubscribe(user_id, all = false, campaign_ids = nil)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.subscription user_id, true, all, campaign_ids
  end

  def self.subscribe(user_id, all = false, campaign_ids = nil)
    if @ob.nil?
      res = Result.new Outbound::ERROR_INIT, false
      @logger.error res.error
      return res
    end
    @ob.subscription user_id, false, all, campaign_ids
  end

  class Result
    include Defaults

    def initialize(error, received_call)
      @error = error
      @received_call = received_call
    end

    attr_accessor :error
    attr_accessor :received_call

    def success?
      @received_call && @error.nil?
    end

    def user_id_error?
      @error == Outbound::ERROR_USER_ID
    end

    def event_name_error?
      @error == Outbound::ERROR_EVENT_NAME
    end

    def connection_error?
      @error == Outbound::ERROR_CONNECTION
    end

    def init_error?
      @error == Outbound::ERROR_INIT
    end

    def token_error?
      @error == Outbound::ERROR_TOKEN
    end

    def platform_error?
      @error == Outbound::ERROR_PLATFORM
    end

    def campaign_id_error?
      @error == Outbound::ERROR_CAMPAIGN_IDS
    end
  end

  class Client
    include Defaults

    def initialize(api_key, logger, base_url: base_url)
      @api_key = api_key
      @logger = logger
      @base_url = base_url
    end

    def alias(user_id, previous_id)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless previous_id.is_a?(String) || previous_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_PREVIOUS_ID, false
        @logger.error res.error
        return res
      end

      user_data = { user_id: user_id, previous_id: previous_id }
      post(@api_key, '/identify', user_data)
    end

    def identify(user_id, info = {})
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      user_data = { user_id: user_id }
      begin
        user = user(info)
        user_data = user_data.merge user
      rescue
        @logger.error "Could not use user info (#{info}) and/or user attributes #{attributes} given to identify call."
      end

      post(@api_key, '/identify', user_data)
    end

    def track(user_id, event, properties = {}, _user_info = {}, timestamp = Time.now.to_i)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless event.is_a? String
        res = Result.new Outbound::ERROR_EVENT_NAME, false
        @logger.error res.error
        return res
      end

      data = { user_id: user_id, event: event }

      if properties.is_a? Hash
        data[:properties] = properties unless properties.empty?
      else
        @logger.error "Could not use event properties (#{properties}) given to track call."
      end

      data[:timestamp] = timestamp
      puts timestamp

      post(@api_key, '/track', data)
    end

    def disable(platform, user_id, token)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
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

      post(@api_key, "/#{platform}/disable", token: token, user_id: user_id)
    end

    def disable_all(platform, user_id)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless [Outbound::APNS, Outbound::GCM].include? platform
        res = Result.new Outbound::ERROR_PLATFORM, false
        @logger.error res.error
        return res
      end

      post(@api_key, "/#{platform}/disable", all: true, user_id: user_id)
    end

    def register(platform, user_id, token)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
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

      post(@api_key, "/#{platform}/register", token: token, user_id: user_id)
    end

    def subscription(user_id, unsubscribe = false, all = false, campaign_ids = nil)
      unless user_id.is_a?(String) || user_id.is_a?(Numeric)
        res = Result.new Outbound::ERROR_USER_ID, false
        @logger.error res.error
        return res
      end

      unless all
        unless !campaign_ids.nil? && campaign_ids.is_a?(Array) && !campaign_ids.empty?
          res = Result.new Outbound::ERROR_CAMPAIGN_IDS, false
          @logger.error res.error
          return res
        end
      end

      url = '/' + (unsubscribe ? 'unsubscribe' : 'subscribe') + '/' + (all ? 'all' : 'campaigns')
      data = { user_id: user_id }
      data[:campaign_ids] = campaign_ids unless all
      post(@api_key, url, data)
    end

    private

    def post(api_key, path, data)
      begin
        headers = HEADERS
        headers['X-Outbound-Key'] = api_key
        payload = JSON.generate data
        uri = URI("#{@base_url}#{path}")

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
      if status < 200 || status >= 400
        err = status.to_s
        err << " - #{res.body}" unless res.body.empty?
      end
      [err, true]
    end

    def user(info = {})
      raise unless info.is_a? Hash

      user = {
        first_name: info[:first_name],
        last_name: info[:last_name],
        email: info[:email],
        phone_number: info[:phone_number],
        apns: info[:apns_tokens],
        gcm: info[:gcm_tokens],
        group_id: info[:group_id],
        group_attributes: info[:group_attributes],
        previous_id: info[:previous_id],
        attributes: info[:attributes]
      }
      user.delete_if { |_k, v| v.nil? || v.empty? }
    end
  end
end
