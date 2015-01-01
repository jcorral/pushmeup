require 'httparty'
require 'json'

module Pushmeup::Fire

  class Gateway
    include HTTParty

    HOST = 'https://api.amazon.com/messaging/registrations/%s/messages'

    attr_accessor :access_token_expiration, :access_token

    def initialize(options={})
      @options = options
    end

    def client_id
      @client_id ||= @options[:client_id] || Pushmeup.configuration.fire_client_id
    end

    def client_secret
      @client_secret ||= @options[:client_secret] || Pushmeup.configuration.fire_client_secret
    end

    def send_notification(device_token, data = {}, options = {})
      n = Pushmeup::Fire::Notification.new(device_token, data, options)
      send_notifications([n])
    end

    def send_notifications(notifications)
      prepare_token
      responses = []
      notifications.each do |n|
        responses << prepare_and_send(n)
      end
      responses
    end


    def prepare_token
      return if Time.now.to_i < access_token_expiration.to_i

      token                   = get_access_token
      access_token            = token['access_token']
      expires_in_sec          = token['expires_in']
      access_token_expiration = Time.now + expires_in_sec - 60
    end

    def get_access_token
      headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
      body    = {
        grant_type:    'client_credentials',
        scope:         'messaging:push',
        client_id:     client_id,
        client_secret: client_secret
      }
      params = {headers: headers, body: body}
      res = post('https://api.amazon.com/auth/O2/token', params)
      return res.parsed_response if res.response.code.to_i == 200
      raise 'Error getting access token'
    end


    def prepare_and_send(n)
      if !n.consolidationKey.nil? && n.expiresAfter.nil?
        raise %q{If you are defining a "colapse key" you need a "time to live"}
      end
      send_push(n)
    end

    def send_push(n)
      headers = {
          'Authorization'       => "Bearer #{access_token}",
          'Content-Type'        => 'application/json',
          'Accept'              => 'application/json',
          'X-Amzn-Accept-Type'  => 'com.amazon.device.messaging.ADMSendResult@1.0',
          'X-Amzn-Type-Version' => 'com.amazon.device.messaging.ADMMessage@1.0'
      }

      body = {
          :data => n.data
      }
      body.merge!({consolidationKey: n.consolidationKey}) if n.consolidationKey
      body.merge!({expiresAfter: n.expiresAfter}) if n.expiresAfter
      send_to_server(headers, body.to_json, n.device_token)
    end

    def send_to_server(headers, body, token)
      params = {:headers => headers, :body => body}
      device_dest = HOST % [token]
      response = post(device_dest, params)
      build_response(response)
    end

    def build_response(response)
      case response.code
        when 200
          {:response =>  'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
        when 400
          {:response => response.parsed_response, :status_code => response.code}
        when 401
          {:response => 'There was an error authenticating the sender account.', :status_code => response.code}
        when 500
          {:response => 'There was an internal error in the Amazaon server while trying to process the request.', :status_code => response.code}
        when 503
          {:response => 'Server is temporarily unavailable.', :status_code => response.code}
      end
    end

  end

end
