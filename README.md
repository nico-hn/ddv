# Ddv

Ddv is a recursive directory listing command with very limited functionality.

## Installation (not published to RubyGems.org yet)

Add this line to your application's Gemfile:

    gem 'ddv'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ddv

## Usage

execute:

    ddv [top_directory_name_to_list]

For example:

    $ ddv data
    [data]
      * README
      * index.html
      [aves]
        * index.html
        [can_fly]
          * sparrow.txt
        [cannot_fly]
          * ostrich.jpg
          * ostrich.txt
          * penguin.jpg
          * penguin.txt
      [mammalia]
        * index.html
        [can_fly]
          * bat.txt
        [cannot_fly]


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
