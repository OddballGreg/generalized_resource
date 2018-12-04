# Generalized Resource

[![Gem Version](https://badge.fury.io/rb/generalized_resource.svg)](http://badge.fury.io/rb/generalized_resource)

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Features](#features)
  - [Requirements](#requirements)
  - [Setup](#setup)
  - [Usage](#usage)
  - [Config](#config)
  <!-- - [Tests](#tests) -->
  - [Versioning](#versioning)
  <!-- - [Code of Conduct](#code-of-conduct) -->
  <!-- - [Contributions](#contributions) -->
  - [License](#license)
  <!-- - [History](#history) -->
  - [Credits](#credits)

<!-- Tocer[finish]: Auto-generated, don't remove. -->


## Features
- Consistent, ActiveRecord-like chainable DSL for making rich and understandable queries to an API.
- Syntax developed to allow highly configurable and logical queries against the database such as like queries on string fields, paginated requests and ordering.
- Developed to interact wtih the (GeneralizedApi)[https://github.com/OddballGreg/generalized_api] gem to get your microservices communicating with minimum fuss.  

## To Do
- Negative (not) requests.
- Advanced Query Requests. Allow the requester to offload relational queries to SQL on the API server rather than reconstruct the joins manually after requesting both tables of information.
- Consider reducing the size and load of the gem by rewriting the ActiveSupport helpers and avoiding the large import.
- Consider moving over the http.rb for slightly faster communication times compared to the current HTTParty implementation.
- Global Raw Request Flag
- Remove need to stipulate to_a for relations wherever possible.
- Bulk update/destroy methods
- Non-Relation methods that have a "raw" option should receive such in an options hash, rather than passing true without explanation.
- Provide a spec suite.
- Make the GeneralizedResource interpretations of data returns configurable.
- has/belongs_to through relationships
- Configurable relation/field names. 
- Relationships between API's

## FAQ
### Why?
I wanted something that could quickly, consistently and DRYly return JSON data from a Rails API server to facilitate a microservice based architecture. I grew tired of needing to update controllers and other nonsense every single time a new model, especially when the only thing that changed between each model was what parameters I would permit. Having 18 controllers doing the same thing 18 times was the antithesis of D.R.Y. in my opinion.

### Does it work and should I use it in production?
GeneralizedResource was developed as it was used in production for multiple commercial api applications, and has proven to be a stable, consistent and decently fast way to communicate with a API within the context of a rails environment.

### Is there something better out there?
As far as I know, maybe. I was not aware of the functionality of GraphQL when I built this and GeneralizedApi, which somewhat fufills the same niche without following standard restful practices or rails conventions. Like anything in software, it might subjectively be the better choice depending on your use case, so only you can answer this question for yourself.

I had also previously used Her before deciding to write GeneralizedApi, but found it's implementation to be lacking in polish, and frequently found it more frustrating than useful. It was also, as far as I remember, ActiveRecord specific, whereas GeneralizedApi can, and has succesfully been, engaged with through NodeJS and Ajax, and pleasantly combined with Vue.Js and Redux as part of that implementation.

## Requirements

0. [Ruby 2.5.0](https://www.ruby-lang.org)
0. [Ruby on Rails](http://rubyonrails.org)
0. Other requirements will be fufilled via the Gemfile.

## Setup

To install, run:

    gem install generalized_resource

Add the following to your Gemfile:

    gem "generalized_resource"

### Config

Place the following in config/initializers/generalized_resource.rb and create the approprate schema file following the format provided in the sample_schema.yml file.

```ruby
GeneralizedResource.config do |config|
  config[:schema_paths] = ["#{Rails.root}/config/sample_schema.yml"]
end
```

GeneralizedResource has no Rails hooks built into it, so if you're not using, just make sure that the location you pass to the :schema_paths are absolute paths.

There are various additional configuration options which GeneralizedResource will use to instantiate itself within your applications environment, the defaults for which can be seen below:

```ruby
  custom_top_context_name: 'GR',
  define_modules_at_top_context: false,
  define_models_at_top_context: false,
  request_logging: true,
```

- custom_top_context_name is a variable which GeneralizedResource will use to alias the GeneralizedResource namespace should you find that verbose to write out repeatedly. Set to `nil` to deactive this behaviour.
- define_modules_at_top_context is a flag that can be set if you would prefer not needing to resolve GeneralizedResource at all to access your resources. ie `Api::Customer.first`
- define_models_at_top_context is a flag that can be set if you would prefer not needing to resolve GeneralizedResource or the server which your resource resides at. ie `Customer.first`
- request_logging is exactly what it says on the box. The exact contents and style of a request are `puts`ed out by default for debug/logging purposes. This can become extremely verbose depending on your code use, but the quantity of requests is as handy as ActiveRecords sql request logging for spotting poorly optimized code.

Do note that defining the modules and models at the top context can have unforseen consequences should the Api's or Model's you define clash with with anything already defined within the Rails namespace **or each other**.

## Usage

The generalized resource gem was constructed in tandem with [GeneralizedApi]() as a way to provide a standard, conventional and consistent API interface which the GeneralizedResource gem could interact with via a chainable API riffing on ActiveRecord's Relation syntax, while also being interactable from any application that could configure the necessary parameters via the relevant REST request for the desired action.

**Do Note** that due to the GeneralizedResource's expectation that it will be speaking to a GeneralizedApi, attempting to use it to interact with other styles of API's may not work, but would not be impossible to configure without some adapters and new configuration settings. An example of this is GeneralizedResources expectation of GeneralizedApi's standard return formatting in the below styles:

Expected response for a succesful show/update/create action where the return is a singular instance of the model called 'Customer':

```
{ 
  error: false,
  customer: {
    full_name: "Barney Stinson",
    first_name: "Barney",
    surname: "Stinson"
  }

}, status: :ok
```

Expected response for a succesful index/query/search action where the return is a plural array of 'Customer's:

```
{ 
  error: false,
  customers: [
    {
      full_name: "Barney Stinson",
      first_name: "Barney",
      surname: "Stinson"
    },
    {
      full_name: "Frank Barnes",
      first_name: "Frank",
      surname: "Barnes"
    }
  ]

} , status: :ok
```

GeneralizedApi by standard uses standard 200 Content Ok for succesful requests, or 422 Unprocessable Entity for requests which is unable to handle but understands. Misunderstood requests (due to pathing or whatever issue) will result in a 500 Server Error as expected.

Non-standard REST default behaviour of GeneralizedApi, in addition to keying the type of the models in its response, is to return `error: false` or `error: true` as part of the body in the event that it was unable to process the request, usually create/update/delete. In these instances, the ActiveRecord.errors.full_messages response is returned as below:

```
{
  error: true,
  messages: [
    "Full Name may not be blank!",
    "Surname may not be blank!"
  ]

}, status: :unprocessable_entity
```

### Basic Requests

Assuming you have used the sample schema and possess and have configured a GeneralizedApi application with matching models, the below would be possible:

```ruby
GeneralizedResource::Api::Customer.all.to_a
```

The above line may look somewhat familiar to Rails developers, but to break down what is occuring:
- The stipulation of Api to GeneralizedResource is a way of quanitifying the server from which the information should be retrieved. The sample_schema.yml describes the "base_url" the "api" server is located at, as well as any base route stipulations to where GeneralizedApi may be mounted, typically api/v1 per Rails convention.
- Resolution to Customer engages the Customer model described within the "api" space.
- The method `all`, like ActiveRecord, describes a desire to request all records from the database. Unlike ActiveRecord however, it's generally undesireable to do this both from a Server and Client perspective, as doing this to large database can hang both the Server and Client. As such, despite the name, GeneralizedApi defaults an all request to the first 1000 records.
- The method `to_a`, when called on the relation object returned by `all`, calls down the `execute` method for relations, which fires off the GET request to the API, recieves and parses the reponse, and generates an array of the requested GeneralizedResource model objects to be interacted with.
  - As a side note, some effort has been made to make GeneralizedResource::Relations implicitely react to methods that call to the data such as `each`, so the `to_a` call may not always be necessary depending on your next action with the data.

### Accessing All Data

If you are certain you would like every record from the database, you can use another ActiveRecord-like behaviour to trigger a series of requests for batches of the data in sequence to be used in a block, or to be gathered in your memory all at once.

```ruby 
GeneralizedResource::Api::Customer.all.find_each do |customer|
  puts customer.name
end 

#or

potentially_absurdly_large_array = GeneralizedResource::Api::Customer.all.collect
```

### Pagination

If you are familiar with the inner workings of the ActiveRecord, you might be aware that find_each merely uses the `Limit` and `Offset` keywords of SQL to trigger sequential queries and reduce memory load. GeneralizedResource uses exactly the same concept through GeneralizedApi, which uses will_paginate to provide a pagination syntax to the API. This can be manually used as follows:

```ruby 
GeneralizedResource::Api::Customer.paginate(page: 1, per_page: 1).each do |customer|
  puts customer.name
end 

# Al Capone
```

### Querying
Of course, ActiveRecords most generally used feature is it's querying of attributes, which is equally possible through GeneralizedResource.

```ruby 
puts GeneralizedResource::Api::Customer.where(first_name: 'Alan', surname: 'Rickman').first.full_name

# Alan Rickman
```

For additional power, GeneralizedApi also exposes syntax for performing case-insensitive like searches against a string column provided the database supports it.  

```ruby
pp GeneralizedResource::Api::Customer.like(full_name: 'Al').collect.map(&:full_name)

# Al Capone
# Alan Rickman
# Alan Turing
# Alanis Morissette
```

### Ordering

GeneralizedApi allows you to specify an attribute to request the results in a specific order via the SQL.

```ruby
pp GeneralizedResource::Api::Customer.like(full_name: 'Al').order_by('surname DESC').collect.map(&:full_name)

# Al Capone
# Alanis Morissette
# Alan Rickman
# Alan Turing
```

### Creating/Updating/Deleting

Creating, updating and deleting using the GeneralizedResource is near identical to ActiveRecord.

```ruby
GeneralizedResource::Api::Customer.create(surname: 'Angela', first_name: 'Michael')
# <Customer, id: 10>
GeneralizedResource::Api::Customer.find(10).update(surname: 'Angelo')
# <Customer, id: 10>
GeneralizedResource::Api::Customer.find(10).destroy
#or
GeneralizedResource::Api::Customer.destroy(10)
```

### Raw Data

You may have found the previous examples ability to destroy a Customer by Id without first requesting the Customer a bit unusual. GeneralizedResource was used to build a data middleman, and as such, needed to be quick in it's data returns as much as possible. To this end, it made no sense to request and parse data, only to re-encode it as JSON again and forward it.

As a result, the relation syntax bears a special method, `raw`, which can be used to instruct GeneralizedResource to not parse and instantiate GeneralizedResource objects from the response, rather just returning the hash structured data immediately.

```ruby 
GeneralizedResource::Api::Customer.raw.paginate(page: 1, per_page: 1).each do |customer|
  puts customer['name']
end 

# Al Capone
```

Some non-relation methods also contain optional flags to engage the raw behaviour, such as find, though this not currently very elegant or self-explantory.

```ruby 
customer = GeneralizedResource::Api::Customer.find(10, true)

GeneralizedResource::Api::Customer.destroy(customer['id'])
```

### Count

A very typical use case for data is to know the number of something, usually within the bounds of some criteria. As such, GeneralizedApi also responds to requests for the count of something, even when scoped by query.

```ruby 
total_customer_count = GeneralizedResource::Api::Customer.count
# 53

alan_customer_count = GeneralizedResource::Api::Customer.where(first_name: 'Alan').count
# 2
```

<!-- ## Tests

To test, run:

    bundle exec rake -->

## Versioning

Read [Semantic Versioning](http://semver.org) for details. Briefly, it means:

- Major (X.y.z) - Incremented for any backwards incompatible public API changes.
- Minor (x.Y.z) - Incremented for new, backwards compatible, public API enhancements/fixes.
- Patch (x.y.Z) - Incremented for small, backwards compatible, bug fixes.

<!-- ## Code of Conduct

Please note that this project is released with a [CODE OF CONDUCT](CODE_OF_CONDUCT.md). By
participating in this project you agree to abide by its terms.

## Contributions

Read [CONTRIBUTING](CONTRIBUTING.md) for details. -->

## License

Copyright 2018 []().
Read [LICENSE](LICENSE.md) for details.

<!-- ## History

Read [CHANGES](CHANGES.md) for details.
Built with [Gemsmith](https://github.com/bkuhlmann/gemsmith). -->

## Credits

Developed by [Gregory Havenga](https://github.com/OddballGreg) at
[]().
