module GeneralizedResource
  class Relation
    extend GeneralizedResource::Client
    include GeneralizedResource::Client

    attr_reader :model_name, :pagination, :options, :module_name

    def initialize(model_name, module_name, options={}, pagination=nil, ordering=nil)
      @model_name = model_name
      @module_name = module_name
      @pagination = pagination
      @options = {model_key.to_sym => options}
      @ordering = ordering
      @raw = options[:raw] || false
      options.delete(:raw)
      @search_params = nil
    end

    def like(options={})
      options.each do |k,v|
        @search_params = {search_field: k.to_s, search_string: v}
      end

      self
    end

    def paginate(options={})
      if options[:per_page] && options[:page]
        @pagination = {per_page: options[:per_page].to_i, page: options[:page].to_i}
      else
        throw 'Attempted to paginate query without providing per_page and page params'
      end

      self
    end

    def raw
      @raw = true
      self
    end

    def all
      self
    end

    def order_by(field_name)
      @ordering = field_name.to_s if field_name
      self
    end

    def where(options={})
      if @options[model_key.to_sym]
        @options[model_key.to_sym] = @options[model_key.to_sym].merge(options)
      else
        @options = {model_key.to_sym => options}
      end
      self
    end

    def find_by(options={})
      @options = {model_key.to_sym => options}

      result = execute
      if result.count == 1
        return result.last
      elsif result.count == 0
        return nil
      else
        return result
      end
    end

    def create(options={})
      response = self.client_post(route, {model_key.to_sym => options.merge(@options[model_key.to_sym])})
      return response if response['error'] || raw
      model.new(response[model_key])
    end

###### Implement scoped find or destroys
    # def find(id)
    #   response = self.client_get("#{route}/#{id}")
    #   return nil if response['error']
    #   parse_models(response, multiple: false)
    # end

    # def destroy(id)
    #   self.client_destroy("#{route}/#{id}")
    # end
####

    def execute
      if @options[model_key.to_sym].keys.count.zero? && @pagination.nil? && @ordering.nil? && (@search_params.nil? || (@search_params.keys & %i(search_field search_string)).count != 2)
        parse_models(self.client_get(route))
      else
        options = @options
        options = options.merge({per_page: @pagination[:per_page], page: @pagination[:page]}) if @pagination
        options = options.merge(order_by: @ordering) if @ordering
        if @search_params && (@search_params.keys & %i(search_field search_string)).count == 2
          options = options.merge(@search_params) if @search_params
          parse_models(self.client_post("#{route}/search", options))
        else
          parse_models(self.client_post("#{route}/query", options))
        end
      end
    end

    def to_a
      execute
    end

    def count
      puts 'Warning: Fuzzy Search Parameters are discarded for count requests' if @search_params
      if @options.keys.count.positive?
        response = self.client_post("#{route}/query/count", options)
        if response['error'] == false && !@raw
          response[model_key.pluralize+'_count']
        else
          response
        end
      else
        response = self.client_get("#{route}/count")
        if response['error'] == false && !@raw
          response[model_key.pluralize+'_count']
        else
          response
        end
      end
    end

    def last
      all.execute.last
    end

    def first
      paginate({per_page: 1, page: 1}).execute.first
    end

    def map
      results = []
      to_a.each do |item|
        results << (yield item)
      end
      results
    end

    def find_each(options={})
      @pagination = {}
      @pagination[:page] = options[:start_page] || 1
      @pagination[:per_page] = options[:batch_size] || 1000
      results = (@raw ? to_a[model_key.pluralize] : to_a)
      while results.count.positive? do
        results.each do |item|
          yield item
        end
        @pagination[:page] += 1
        results = (@raw ? to_a[model_key.pluralize] : to_a)
      end
    end

    def each
      to_a.each do |item|
        yield item
      end
    end
    
    def collect
      results = []
      find_each do |response| 
        results << response
      end
      results.flatten
    end

    private

    def parse_models(response)
      return response if @raw || response[model_key.pluralize].nil?
      if model.respond_to?(:new)
        response[model_key.pluralize].map{|object| model.new(object)}
      else
        GeneralizedResource::Base.new(object)
      end
    end
  end
end