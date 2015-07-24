require 'fileutils'
require 'colorize'

module Dvm
  class CLI

    def initialize(root, repo)
      @root = root
      @repo = repo
    end

    def path(p)
      File.join @root, p
    end

    def scm
      path 'scm'
    end

    def current
      path 'current'
    end

    def current_path(*p)
      File.join current, p
    end

    def releases
      path 'releases'
    end

    def release(v)
      File.join releases, v
    end

    def share
      path 'share'
    end

    def share_path(*p)
      File.join share, p
    end

    def shared_dirs
      %w(public/upload log vendor)
    end

    def shared_files
      Dir.glob(current_path('config', '**', '*.example')).collect do |c|
        File.join 'config', c.split('config')[1][1..-1].split('.')[0..-2].join('.')
      end
    end

    def version(order)

    end

    def new_version(version)

    end

    def drop_version(version)

    end


    def clone
      run_cmd "git clone --bare #{@repo} #{scm}"
    end


    def checkout
      version = `cd #{scm};git rev-parse --short HEAD`.strip
      vd = release version
      FileUtils.makedirs vd
      run_cmd "cd #{scm};git archive master | tar -x -f - -C #{vd}"
      run_cmd "echo #{version} > #{vd}/REVISION"
      new_version version
      version
    end


    def copy_config
      Dir.glob(current_path('config', '**', '*.example')).each do |c|
        puts c
        FileUtils.cp c, share_path('config', c.split('config')[1][1..-1].split('.')[0..-2].join('.'))
      end
    end


    def link_current(v)
      run_cmd "unlink #{current}" if File.directory? current
      run_cmd "ln -s #{release(v)} #{current}"
    end


    def link_shared
      shared_dirs.each do |e|
        run_cmd "rm -rf #{current_path(e)};ln -s #{share_path(e)} #{File.dirname(current_path(e))}"
      end

      shared_files.each do |e|
        run_cmd "rm -f #{current_path(e)};ln -s #{share_path(e)} #{current_path(e)}"
      end
    end


    def vam_install
      log_action 'Vam install'
      run_cmd "cd #{current};vam install" if File.exist? File.join(current, 'Vamfile')
    end


    def assets_precompile
      log_action 'Rails assets precompile'
      run_cmd "cd #{current};RAILS_ENV=production bundle exec rake assets:precompile"
    end


    def db_setup
      log_action 'Rails db setup'
      run_cmd "cd #{current};RAILS_ENV=production bundle exec rake db:setup"
    end


    def bundle_install
      log_action 'Rails bundle install'
      run_cmd "cd #{current};RAILS_ENV=production bundle install --deployment"
    end


    def init_install
      log_action 'Git clone'
      clone
      link_current checkout

      log_action 'Copy & Link config files'
      shared_dirs.each { |e| FileUtils.makedirs share_path(e) }
      shared_files.each { |e| FileUtils.makedirs File.dirname(share_path(e)) }
      copy_config
      link_shared

      bundle_install
      vam_install
      assets_precompile

      puts '======= Deploy success ======'.colorize :green
    end


    def pull
      run_cmd "cd #{scm};git fetch origin master:master"
    end


    def update
      log_action 'Git pull'
      pull
      link_current checkout

      log_action 'Link config files'
      link_shared

      bundle_install
      vam_install
      assets_precompile

      puts '======= Deploy success ======'.colorize :green
    end


    def log_action(action)
      puts "\n======= #{action} =======".colorize :blue
    end


    def run_cmd(cmd)
      puts "#RUN[ #{cmd} ]"
      system cmd
    end


    def start
      if Dir.exist? current
        `cd #{current};bundle exec pumactl start`
      elsif File.exist? 'Gemfile'
        `pumactl start`
      else
        puts 'Start server failed.'.colorize :red
      end
      puts 'Start server success.'.colorize :green
    end


    def stop
      if Dir.exist? current
        `cd #{current};kill -9 \`cat tmp/server.pid\``
      elsif File.exist? 'Gemfile'
        `kill -9 \`cat tmp/server.pid\``
      else
        puts 'Stop server failed.'.colorize :red
      end
      puts 'Stop server success.'.colorize :green
    end


    def restart
      stop
      start
    end


    def self.run(argv)
      if argv.length >0
        action = argv[0]
        if action == 'remote'
          puts '1'

        elsif action == 'update'
          CLI.new(Dir.getwd, '').update
        elsif action == 'start'
          CLI.new(Dir.getwd, '').start
        elsif action == 'stop'
          CLI.new(Dir.getwd, '').stop
        elsif action == 'restart'
          CLI.new(Dir.getwd, '').restart
        else
          root = Dir.getwd
          repo = action

          if action.start_with? 'g:'
            repo = "git@github.com:#{action[2..-1]}.git"
          elsif action.start_with? 'b:'
            repo = "git@bitbucket.org:#{action[2..-1]}.git"
          end

          if argv[1]
            root = File.join root, argv[1]
          else
            root = File.join root, File.basename(repo, File.extname(repo))
          end

          CLI.new(root, repo).init_install

        end
      else

      end
    end

  end
end
