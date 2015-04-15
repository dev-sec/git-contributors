require 'diffy'
require 'inquirer'

class Readme
  def initialize path = 'README.md', ignore: []
    @path = path
    @old = File::read path
    @replacer = contrib_string
    @users = {}
    @ignore = []
  end

  def ensure_user user
    login = user['login']
    if @users.key? login
      puts "ww user already defined: #{login}"
    end

    if @ignore.include? login
      puts ".. ignoring #{login}"
    else
      puts "++ #{login}"
      @users[login] = user
    end
  end

  def save
    nu_contribs = @users.values.
      sort_by{|x| -x['stats']['contributions']}.
      map do |x|
        (x['name'] || '') + " ["+x['login']+"]("+x['html_url']+")"
      end.join("\n* ")

    nu = @old.sub(@replacer, "\n* " + nu_contribs)

    puts Diffy::Diff.new( @old, nu, context: 2 ).to_s
    if Ask.confirm "Save this?", default: false
      File::write @path, nu
    end
  end

  private

  def contrib_string
    m = @old.match /(?:\n## Contributors[^\n]*\n)(?<names>(\n\* [^\n]+)+)/
    return '' if m.nil?
    m['names']
  end

end
