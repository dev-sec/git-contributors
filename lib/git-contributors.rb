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

  def initialize owner, repo
    @user = owner
    @repo = repo
    @users = nil
  end

  def self.for_github_org org
    github = RepoProvider::Github.new.provider
    repos = github.org_repositories('hardening-io')

    contributors = {}
    contribs = repos.map do |repo|
      GitContributors.new org, repo['name']
    end.each do |contrib|
      contrib.users.each do |u|
        contributors[u['login']] ||= u
        o = contributors[u['login']]
        o['stats']['repos'] ||= 0
        o['stats']['repos'] += 1
        o['stats']['contributions'] += (u['stats']['contributions'] || 0)
      end
    end

    gc = GitContributors.new nil, nil
    gc.users = contributors
    gc.print_contributors
  end

  def self.for_path path
    gi = GitIssues.new
    prov = gi.gitReposFor(path)
    Log.abort "no github repo here?" if prov.empty?
    user = prov[0].repo['user']
    repo = prov[0].repo['repo'].sub(/\.git/,'')
    GitContributors.new user, repo
  end

  def users
    @users || load_contributors
  end
  def users= u
    @users = u
  end

  def load_contributors
    github = RepoProvider::Github.new.provider
    userlist = github.contributors("#{@user}/#{@repo}")

    print "Load #{userlist.length} contributors for #{@user}/#{@repo}"
    @users = userlist.map do |uinfo|
      r = github.user(uinfo['login'])
      r['stats'] = uinfo
      print '.'
      r
    end
    print "\n"
    @users
  end

  def print_contributors opts
    format = opts[:format] || FORMAT

    puts
    users.each do |user|
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
