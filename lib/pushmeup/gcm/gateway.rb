require 'httparty'
require 'json'

module Pushmeup::GCM

  class Gateway
    include HTTParty

    HOST   = 'https://android.googleapis.com/gcm/send'

    def initialize(options={})
      @options = options
    end

    def key
      @key ||= @options[:key] || Pushmeup.configuration.gcm_key
    end

    def host
      @host ||= @options[:host] || Pushmeup.configuration.gcm_host || HOST
    end

    def send_notification(device_tokens, data = {}, options = {})
      n = Pushmeup::GCM::Notification.new(device_tokens, data, options)
      send_notifications([n])
    end

    def send_notifications(notifications)
      responses = []
      notifications.each do |n|
        responses << prepare_and_send(n)
      end
      responses
    end

    def prepare_and_send(n)
      if n.device_tokens.count < 1 || n.device_tokens.count > 1000
        raise "Number of device_tokens invalid, keep it betwen 1 and 1000"
      end
      if !n.collapse_key.nil? && n.time_to_live.nil?
        raise %q{If you are defining a "colapse key" you need a "time to live"}
      end

      self.send_push_as_json(n)
    end

    def self.send_push_as_json(n)
      headers = {
        'Authorization' => "key=#{ key }",
        'Content-Type' => 'application/json',
      }
      body = {
        :registration_ids => n.device_tokens,
        :data => n.data,
        :collapse_key => n.collapse_key,
        :time_to_live => n.time_to_live,
        :delay_while_idle => n.delay_while_idle
      }
      return send_to_server(headers, body.to_json)
    end

    def send_to_server(headers, body)
      params = {:headers => headers, :body => body}
      response = post(params)
      return build_response(response)
    end

    def build_response(response)
      case response.code
      when 200
        {:response =>  'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
      when 400
        {:response => 'Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields.', :status_code => response.code}
      when 401
        {:response => 'There was an error authenticating the sender account.', :status_code => response.code}
      when 500
        {:response => 'There was an internal error in the GCM server while trying to process the request.', :status_code => response.code}
      when 503
        {:response => 'Server is temporarily unavailable.', :status_code => response.code}
      end
    end


  end

end
