# encoding: utf-8
require 'rubygems'
require 'bundler'

Bundler.require

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]

class Ironweb < Sinatra::Base
  set :root, File.dirname(__FILE__)

  register Sinatra::AssetPack
  register Sinatra::AdvancedRoutes
  register Sinatra::Reloader if development?

  helpers do
    def t(*args)
      I18n.t(*args)
    end
    def cache
      @@cache ||= ActiveSupport::Cache::MemoryStore.new()
    end
  end

  assets {
    serve '/',     from: 'assets/public'
    serve '/fonts',     from: 'assets/fonts'
    serve '/js',     from: 'assets/js'
    serve '/css',    from: 'assets/css'
    serve '/img', from: 'assets/img'

    js :app, '/js/app.js', [
      '/js/main.js',
      '/js/vendors/highcharts/highcharts.js'
    ]
    css :app, '/css/application.css', [
      '/css/reset.css',
      '/css/styles.css',
    ]

    js_compression  :jsmin      # Optional
    css_compression :simple       # Optional
  }
  {:fr => '/', :en => '/en/'}.each do |locale, path|
    @@channels = [:greens, :reds, :special]
    @@channels.each do |channel|
      get "#{path}#{channel}" do
        set_locale locale
        params[:channel] = channel
        @title = t 'meta.watching', team: t("meta.#{channel}")
        set_data
        erb :index
      end
    end

    get path do
      set_locale locale
      @title = t 'meta.title'
      params[:channel] ||= :greens
      set_data
      erb :index
    end
  end

  private

  def set_locale locale
    I18n.locale = locale
    I18n.reload! if development?
    params[:locale] = locale
  end

  def set_data
    @channels = @@channels
    @livestream_paths = {
      :reds => '1888101',
      :greens => '1888141',
      :special => '1897350'
    }
    @folks = {
      greens: {
        alefrancois: {
          name: 'Alexandre Lefrançois',
          company: 'Image de Mark',
          role: :integrator,
          twitter: 'enzo_ci'
        },
        ebergeron: {
          name: 'Emilie Bergeron',
          company: ' Vox CG',
          role: :designer,
          twitter: 'emiliebergeron'
        },
        mpesant: {
          name: 'Mathieu Pesant',
          company: 'Cégep de Sainte-Foy',
          role: :integrator,
          twitter: 'MathieuPesant'
        },
        sbouchard: {
          name: 'Sylvain Bouchard',
          company: 'Savoir-faire Linux',
          role: :programmer,
          twitter: 'bouchardsyl'
        },
        ftomalty: {
          name: 'Fletcher Tomalty',
          company: nil,
          role: :programmer,
          twitter: 'fletom'
        },
        asavignac: {
          name: 'Antoine Savignac',
          company: t('sections.folks.from_bordeaux'),
          role: :integrator,
          twitter: 'AntoineSavignac'
        },
      },
      reds: {
        abproulx: {
          name: 'Alexia B. Proulx',
          company: 'Cégep de Sainte-Foy',
          role: :integrator_e,
          twitter: 'Gengenchu'
        },
        cmonchablon: {
          name: 'Cesar Monchablon',
          company: 'Cégep de Sainte-Foy',
          role: :designer,
          twitter: 'PulseDesign'
        },
        dvanderwindt: {
          name: 'Damien Van Der Windt',
          company: 'Nurun',
          role: :integrator,
          twitter: 'damienvdw'
        },
        gesanderson: {
          name: 'Gregory Eric Sanderson',
          company: 'Avencall',
          role: :programmer,
          twitter: 'gelendir'
        },
        jbourassa: {
          name: 'Jimmy Bourassa',
          company: 'Hookt Studios',
          role: :programmer,
          twitter: 'JimmyBourassa'
        },
        bbort: {
          name: 'Benjamin Bort',
          company: t('sections.folks.from_bordeaux'),
          role: :integrator,
        },
      }
    }
    @videos = cache.fetch('videos', :expires_in => 60 * 30) do
      rescue_array do
        Vimeo::Simple::User.videos('webaquebec').parsed_response
      end
    end

    Koala.http_service.http_options = {:ssl => { :verify => false }} if development?
    @photos = cache.fetch('photos', :expire_in => 60 * 5) do
      rescue_array do
        oauth = @oauth = Koala::Facebook::OAuth.new(ENV['FB_APP_ID'], ENV['FB_APP_SECRET'])
        graph = Koala::Facebook::API.new(oauth.get_app_access_token)
        photos = graph.get_object("/#{ENV['FB_ALBUM_ID']}/photos?fields=picture,link,width,height")
        photos.reject { |p| p['height'] > p['width'] }
      end
    end

    @commitsData = cache.fetch('commits', :expire_in => 1) do
      hours = {}
      cstart = Date.new(2013, 2, 19)
      cend = Date.new(2013, 2, 23)
      # During or after competition, commits in each repository during competition
      if Time.now > cstart
        tsince = cstart
        tuntil = cend
        @github_paths = [
          [:reds, 'ironweb', 'rouges'],
          [:greens, 'ironweb', 'verts-frontend'],
          [:greens, 'ironweb', 'verts-backend']
        ]
      # Before competition start, last 72 hours commits in this repo
      else
        @github_paths = {
          :reds => ['ironweb', 'ironweb-live'],
          :greens => ['ironweb', 'ironweb-live'],
        }
        tsince = Time.now - 60*60*72
        tuntil = Time.now
      end
      github = Github.new do |config|
        config.endpoint    = 'https://api.github.com'
        config.oauth_token = ENV['GITHUB_TOKEN']
        config.adapter     = :net_http
        config.ssl         = {:verify => false} if development?
      end
      @github_paths.each do |channel, user, repo|
        hours[channel] = { data: [] } if hours[channel].nil?
        hours[channel][:color] = '#95b1bd'
        commits = github.repos.commits.all(user, repo,
          since: tsince.iso8601,
          until: tuntil.iso8601,
          per_page: 100)
        commits.each_page do |page|
          page.each do |reponse|
            if reponse.commit.committer
              time = reponse.commit.committer.date
            else
              time = reponse.commit.author.date
            end
            hour = ((Time.parse(time).localtime - tuntil.to_time)/60/60).round.abs
            if hours[channel][:data][hour].nil?
              hours[channel][:data][hour] = 1
            else
              hours[channel][:data][hour] = hours[channel][:data][hour] + 1
            end
          end
        end
      end
      hours.each do |channel, values|
        values[:data].fill { |i| values[:data][i] || 0 }
        values[:data].reverse
        hours[channel] = [values]
      end
      hours
    end
  end

  def rescue_array &block
    begin
      block.call
    rescue Exception => exception
      nil
    end
  end
end