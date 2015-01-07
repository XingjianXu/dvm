require 'fileutils'

module Dvm
  class CLI

    def initialize(root, repo)
      @root = root
      @repo = repo
      @dsl = Dsl.new
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
      %w(public/upload log)
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
      `git clone --bare #{@repo} #{scm}`
    end


    def checkout
      version = `cd #{scm};git rev-parse --short HEAD`.strip
      vd = release version
      FileUtils.makedirs vd
      `cd #{scm};git archive master | tar -x -f - -C #{vd}`
      `echo #{version} > #{vd}/REVISION`
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
      `unlink #{current}` if File.directory? current
      `ln -s #{release(v)} #{current}`
    end


    def link_shared
      shared_dirs.each do |e|
        `rm -rf #{current_path(e)};ln -s #{share_path(e)} #{File.dirname(current_path(e))}`
      end

      shared_files.each do |e|
        `rm -f #{current_path(e)};ln -s #{share_path(e)} #{current_path(e)}`
      end
    end


    def vam_install
      `cd #{current};vam install` if File.exist? File.join(current, 'Vamfile')
    end


    def assets_precompile
      `cd #{current};RAILS_ENV=production bundle exec rake assets:precompile`
    end


    def db_setup
      `cd #{current};RAILS_ENV=production bundle exec rake db:setup`
    end


    def bundle_install
      `cd #{current};RAILS_ENV=production bundle install`
    end


    def init_install
      clone
      link_current checkout
      shared_dirs.each { |e| FileUtils.makedirs share_path(e) }
      shared_files.each { |e| FileUtils.makedirs File.dirname(share_path(e)) }
      copy_config
      link_shared
      bundle_install
      vam_install
      assets_precompile
      db_setup

      puts '======= Deploy success ======'
    end


    def pull
      `cd #{scm};git pull`
    end


    def update
      pull
      link_current checkout
      link_shared
      `cd #{current};RAILS_ENV=production bundle install`
      `cd #{current};vam install`
      `cd #{current};RAILS_ENV=production bundle exec rake assets:precompile`

      puts '======= Deploy success ======'
    end


    def self.run(argv)
      if argv.length >0
        action = argv[0]
        if action == 'remote'
          puts '1'

        elsif action == 'update'
          CLI.new(Dir.getwd, '').update
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
