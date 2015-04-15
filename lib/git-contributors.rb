require 'git-issues'
require 'git-issues/providers'
require 'rest-client'
require 'json'
require 'inquirer'
require 'zlog'
Zlog.init_stdout loglevel: :debug

class GitContributors
  Log = Logging.logger[self]
  VERSION = "0.0.1"
  FORMAT = '* %-20LOGIN   %-53NAME'
  PROVIDERS = RepoProviders.new

  attr_reader :repos, :users
  def initialize
    @repos = []
    @users = {}
    @github = RepoProvider::Github.new.provider
  end

  def self.for_github_org user
    gc = GitContributors.new
    gc.add_org user
    gc
  end

  def self.for_path path
    gi = GitIssues.new
    prov = gi.gitReposFor(path)
    Log.abort "no github repo here?" if prov.empty?
    user = prov[0].repo['user']
    repo = prov[0].repo['repo'].sub(/\.git/,'')
    gc = GitContributors.new
    gc.add_repo user, repo
    gc
  end

  def add_org user
    repos = @github.org_repositories('hardening-io')
    puts "Load #{repos.length} repos for #{user}"
    repos.each do |repo|
      add_repo user, repo['name']
    end
  end

  def add_repo user, repo
    @repos.push({ user: user, repo: repo })
    userlist = @github.contributors("#{user}/#{repo}")
    # load all users
    print "Load #{userlist.length} contributors for #{user}/#{repo} "
    userlist.map do |uinfo|
      uid = uinfo['login']
      # progress indication
      print (@users[uid].nil? ? '+' : '.')
      # get the user, if we don't have his/her data yet
      @users[uid] ||= sanitize_user( @github.user(uid) )
      # get or set user stats
      if @users[uid]['stats'].nil?
        @users[uid]['stats'] = uinfo
        @users[uid]['stats']['repos'] = 1
      else
        # we aggregate contributions and repo stats
        @users[uid]['stats']['contributions'] += (uinfo['contributions'] || 0)
        @users[uid]['stats']['repos'] += 1
      end
    end
    print "\n"
  end

  def sanitize_user u
    u['name'] ||= u['login']
    u
  end

  def print_contributors opts
    format = opts[:format] || FORMAT

    puts
    users.each do |id, user|
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
      'stats.repos' => /(%[+-]?\d*)REPOS/,
      'html_url' => /(%[+-]?\d*)URL/,
    }

    # format array contains the position
    # and value that will be inserted into
    # the format string
    format_array = format_REs.
      map do |key, re|
        # get the position and value that
        # will be inserted
        value = key.split('.').reduce(user){|acc,x|acc[x]}
        [ format =~ re, value || '' ]
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
