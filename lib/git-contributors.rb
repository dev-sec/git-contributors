require 'git-issues'
require 'rest-client'
require 'json'
require 'inquirer'
require 'zlog'
Zlog.init_stdout loglevel: :debug


class GitContributors
  Log = Logging.logger[self]
  VERSION = "0.0.1"

  def initialize path
    gi = GitIssues.new
    prov = gi.gitReposFor(path)
    Log.abort "no github repo here?" if prov.empty?

    @user = prov[0].repo['user']
    @repo = prov[0].repo['repo'].sub(/\.git/,'')
    @users = nil
  end

  def load_contributors
    url = "https://api.github.com/repos/#{@user}/#{@repo}/contributors"
    res = RestClient.get url
    userlist = JSON.load(res)

    print "Load #{userlist.length} contributors "
    @users = userlist.map do |uinfo|
      r = JSON.load( RestClient.get uinfo['url'] )
      r['stats'] = uinfo
      print '.'
      r
    end
    print "\n"
  end

  def print_contributors
    @users || load_contributors

    puts "-------------------------------------------------------------------------------"
    puts "| Github ID            | Name                                                 |"
    puts "-------------------------------------------------------------------------------"
    @users.each do |user|
      puts sprintf("* %-20s   %-53s", user['login'], user['name'])
    end
  end

end
