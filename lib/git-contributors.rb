require 'git-issues'
require 'rest-client'
require 'json'
require 'inquirer'
require 'zlog'
Zlog.init_stdout loglevel: :debug


class GitContributors
  Log = Logging.logger[self]
  VERSION = "0.0.1"
  FORMAT = '* %-20LOGIN   %-53NAME'

  def initialize path
    gi = GitIssues.new
    prov = gi.gitReposFor(path)
    Log.abort "no github repo here?" if prov.empty?

    @path = path
    @user = prov[0].repo['user']
    @repo = prov[0].repo['repo'].sub(/\.git/,'')
    @users = nil
  end

  def load_contributors
    url = "https://api.github.com/repos/#{@user}/#{@repo}/contributors"
    res = RestClient.get url
    userlist = JSON.load(res)

    print "Load #{userlist.length} contributors for #{@path}"
    @users = userlist.map do |uinfo|
      r = JSON.load( RestClient.get uinfo['url'] )
      r['stats'] = uinfo
      print '.'
      r
    end
    print "\n"
  end

  def print_contributors opts
    @users || load_contributors
    format = opts[:format] || FORMAT

    puts
    @users.each do |user|
      puts format_user_string(format, user)
    end
    puts
  end

  private

  def format_user_string format, user
    format_REs = {
      'login' => /(%[+-]?\d*)LOGIN/,
      'name' => /(%[+-]?\d*)NAME/,
      'avatar_url' => /(%[+-]?\d*)AVATAR/,
      'stats.contributions' => /(%[+-]?\d*)CONTRIBUTIONS/,
    }
    # format array contains the position
    # and value that will be inserted into
    # the format string
    format_array = format_REs.
      map do |key, re|
        # get the position and value that
        # will be inserted
        value = key.split('.').reduce(user){|acc,x|acc[x]}
        [ format =~ re, value ]
      end.find_all do |x|
        # remove all entries that the user
        # didn't specify
        x[0] != nil
        # sort by entry position for sprintf
      end
    sarray = format_array.sort_by{|x|x[0]}.map{|x|x[1]}
    # sprintf-compatible format string
    # replace all custom format fields with %s
    sformat = format
    format_REs.each do |k,v|
      sformat = sformat.gsub(v, '\1s')
    end
    # print it out
    sprintf(sformat, *sarray)
  end

end
