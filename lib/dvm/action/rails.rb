
action :bundle_install, 'Bundle Install' do
  `cd #{current};RAILS_ENV=production bundle install`
end
