module GeneralizedResource
  class Base
    extend GeneralizedResource::Client
    include GeneralizedResource::Client
    @@clients = Hash.new()

    def initialize(options={})
      options.each do |attribute_name, attribute_value|
        self.class.send(:define_method, "#{attribute_name}=".to_sym) do |value|
          instance_variable_set("@" + attribute_name.to_s, value)
        end

        self.class.send(:define_method, attribute_name.to_sym) do
          instance_variable_get("@" + attribute_name.to_s)
        end

        self.send("#{attribute_name}=".to_sym, attribute_value)
      end

      @@clients[self.class.to_s.to_sym] ||= Hash.new(Hash.new([]))

      (@@clients[self.class.to_s.to_sym][:belongs_to] || []).each do |relation|
        relation_key = relation.tableize.singularize
        raise "#{self.class.to_s} did not recieve a #{relation_key}_id for relation #{relation}. Are you sure the relation exists?" unless self.respond_to?(relation_key + '_id')
        define_singleton_method relation_key.tableize.singularize do
          return nil if self.send(relation_key + '_id').nil?
          "GeneralizedResource::#{module_name}::#{relation.singularize.titleize.gsub(' ', '')}".constantize.find(self.send(relation_key + '_id'))
        end
      end

      (@@clients[self.class.to_s.to_sym][:has_many] || []).each do |relation|
        relation_key = relation.tableize.singularize
        define_singleton_method relation.tableize do
          "GeneralizedResource::#{module_name}::#{relation.singularize.titleize.gsub(' ', '')}".constantize.where(model_key + '_id' => id)
        end
      end

      (@@clients[self.class.to_s.to_sym][:has_one] || []).each do |relation|
        relation_key = relation.tableize.singularize
        define_singleton_method relation_key.tableize.singularize do
          "GeneralizedResource::#{module_name}::#{relation.singularize.titleize.gsub(' ', '')}".constantize.where(model_key + '_id' => id).last
        end
      end
    end

    def self.request_relation(name)
      GeneralizedResource::Relation.new(name.to_s, module_name).where((model_key + '_id').to_sym => self.id)
    end

    def self.all(options={})
      GeneralizedResource::Relation.new(model_name, module_name)
    end

    def self.raw
      GeneralizedResource::Relation.new(model_name, module_name, {raw: true})
    end

    def self.paginate(options={})
      GeneralizedResource::Relation.new(model_name, module_name, {}, {per_page: options[:per_page], page: options[:page]})
    end

    def self.where(options={})
      GeneralizedResource::Relation.new(model_name, module_name, options)
    end

    def self.find_by(options={}, raw=false)
      if raw
        return GeneralizedResource::Relation.new(model_name, module_name, options).raw.find_by(options)
      else
        return GeneralizedResource::Relation.new(model_name, module_name, options).find_by(options)
      end
    end

    def self.like(options={}, raw=false)
      if raw
        return GeneralizedResource::Relation.new(model_name, module_name).raw.like(options)
      else
        return GeneralizedResource::Relation.new(model_name, module_name).like(options)
      end
    end

    def self.find(id, raw=false)
      response = self.client_get("#{route}/#{id}")
      return nil if response['error']
      return response if raw
      model.new(response[model_key])
    end

    def self.create(options={}, raw=false)
      response = self.client_post(route, {model_key.to_sym => options})
      return response if response['error'] || raw
      model.new(response[model_key])
    end

    def self.find_or_create_by!(options={}, raw=false)
      result = self.find_by(options, raw)
      return result if result
      self.create(options, raw)
    end

    def update(options={}, raw=false)
      id = self.id
      response = model.client_put("#{route}/#{id}", {model_key.to_sym => options})
      return response if response['error'] || raw
      model.new(response[model_key])
    end

    def self.destroy(id)
      self.client_destroy("#{route}/#{id}")
    end

    def self.count
      response = self.client_get("#{route}/count")
      if response['error'] == false
        response[model_key.pluralize+'_count']
      else
        response
      end
    end

    def destroy
      self.client_destroy("#{route}/#{@id}")
    end

    def save(raw=false)
      response = model.client_post(route, {model_key.to_sym => @options})
      return response if response['error'] || raw
      model.new(response[model_key])
    end

    def self.last
      begin
        count = self.count
        self.where({per_page: 1, page: count}).last
      rescue
        self.all.last
      end
    end

    def self.first
      self.paginate({per_page: 1, page: 1}).first
    end

    protected

    def self.belongs_to(relations)
      @@clients[self.to_s.to_sym] ||= {}
      @@clients[self.to_s.to_sym][:belongs_to] = relations
    end

    def self.has_many(relations)
      @@clients[self.to_s.to_sym] ||= {}
      @@clients[self.to_s.to_sym][:has_many] = relations
    end

    def self.has_one(relations)
      @@clients[self.to_s.to_sym] ||= {}
      @@clients[self.to_s.to_sym][:has_one] = relations
    end
  end
end
