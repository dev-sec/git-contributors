# Git Contributors

Get git contributors for a folder:

    git contributors /pub/git/git-contributors

Get git contributors for a whole org:

    git contributors --org hardening-io

Use custom formatting, for example for Markdown:

    git contributors . --format "* [%NAME](%URL)"

## Installation

At the moment, build it locally:

    gem build *gemspec
    gem install *gem

Or use bundler

    bundle install
    bundle exec bin/git-contributors .

## Contributing

1. Fork it ( http://github.com/<my-github-username>/git-contributors/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014-15 Dominik Richter
Licensed under MIT