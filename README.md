# antismoker

Yet another HTTP smoke testing framework.

## Installation

Add this line to your application's Gemfile:

    gem 'antismoker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install antismoker

## Usage

The smoke tests are implemented as Rake task.
You can use `antismoker` rake task with adding following lines in your `Rakefile` or so.

    ## Rakefile
    load "tasks/antismoker.rake"

You can configure `antismoker` from `config/antismoker.yml`.

    ## config/antismoker.yml
    # GET http://127.0.0.1/foo
    development:
      127.0.0.1:
        http:
          :port: 80
          :path: /foo
    production:
      127.0.0.1:
        http:
          :port: 80
          :path: /foo

And then run `rake antismoker`.

    % rake antismoker
    smoke testing: http://127.0.0.1:9001/server-status:  [ OK ]


### Capistrano usage

Also you can use `antismoker` from Capistrano.
To use it, add following in your `config/deploy.rb` or so.

    # config/deploy.rb
    require "antismoker/capistrano"
    set(:antismoker_use_rollback, false) # set true to enable rollback on failure

After all, the `antismoker` task will be run after `deploy` and `deploy:cold`.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
