require 'httparty'
require 'pry'
require 'active_support/inflector'

module GeneralizedResource
  module Client
    include HTTParty
    def model_name
      return @model_name if @model_name

      if self.class == Class
        self.to_s.split('::').last
      else
        self.class.to_s.split('::').last
      end
    end

    def module_name
      return @module_name if @module_name

      if self.class == Class
        self.to_s.split('::').last(2).first
      else
        self.class.to_s.split('::').last(2).first
      end
    end

    def model_key
      model_name.tableize.singularize
    end

    def model
      ('GeneralizedResource::' + "#{module_name}::" + model_name).constantize
    end

    def route
      "/#{model_name.tableize}"
    end

    def client_get(url, options={})
      request_wrapper(url, 'GET', options) do
        HTTParty.get(base_url + url, body: options)
      end 
    end

    def client_post(url, options)
      request_wrapper(url, 'POST', options) do 
        HTTParty.post(base_url + url, body: options)
      end 
    end

    def client_destroy(url)
      request_wrapper(url, 'DELETE') do 
        HTTParty.delete(base_url + url)
      end 
    end

    def client_put(url, options)
      request_wrapper(url, 'PUT', options) do 
        HTTParty.put(base_url + url, body: options)
      end
    end

    def request_wrapper(url, method, options={})
      request_start_time = Time.now
      begin
        response = JSON.parse(yield.body)
      rescue JSON::ParserError
        response = {'error' => true, messages: 'Failed to parse response. Internal contact server may have experienced a fault. Please contact support for help.'}
      end
      puts "#{method} #{base_url + url} => #{options} | #{Time.now - request_start_time} seconds" if CONF[:request_logging]
      response
    end

    def base_url
      CONF[:base_urls][module_name.downcase.to_sym]
    end
  end
end
