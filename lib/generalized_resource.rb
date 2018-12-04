def expand_relative_path(file)
  File.expand_path(File.join('../', file), __FILE__)
end

module GeneralizedResource
  CONF = {
    custom_top_context_name: 'GR',
    define_modules_at_top_context: false,
    define_models_at_top_context: false,
    request_logging: true,
    schema_paths: ['sample_schema.yml'],
    base_urls: {}
  }

  require expand_relative_path('generalized_resource/version.rb')
  require expand_relative_path('generalized_resource/client.rb')
  require expand_relative_path('generalized_resource/base.rb')
  require expand_relative_path('generalized_resource/relation.rb')

  def self.config
    yield CONF

    Object.const_set(CONF[:custom_top_context_name], GeneralizedResource)
    CONF[:schema_paths].each do |schema_path|
      schema = YAML.load(File.read(schema_path))
      schema.each do |api_name, api_config|
        api_const_string = api_name.titleize.gsub(' ', '')
        api_const = GeneralizedResource.const_set(api_const_string, Class.new(GeneralizedResource::Base))
        Object.const_set(api_const_string, api_const) if CONF[:define_modules_at_top_context]
        CONF[:base_urls][api_name.to_sym] = api_config['conf']['base_url']

        models = api_config['models']
        if models
          models.each do |model_name, relations|
            model = if CONF[:define_models_at_top_context]
                      Object.const_set(model_name.titleize.gsub(' ', ''), Class.new(api_const))
                    else
                      api_const.const_set(model_name.titleize.gsub(' ', ''), Class.new(api_const))
                    end
            if relations
              model.has_many(relations['has_many']) if relations['has_many']
              model.has_one(relations['has_one']) if relations['has_one']
              model.belongs_to(relations['belongs_to']) if relations['belongs_to']
            end
          end
        end
      end
    end
  end
end
