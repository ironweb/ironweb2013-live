# encoding: utf-8
require 'rubygems'
require 'bundler'

Bundler.require

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]

class Ironweb < Sinatra::Base
  set :root, File.dirname(__FILE__)

  register Sinatra::AssetPack
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
    @@channels = [:greens, :reds]
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
      params[:channel] ||= @@channels.sample
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
      :greens => '1888141'
    }
    @folks = {
      greens: {
        alefrancois: {
          name: 'Alexandre Lefrançois',
          company: 'Image de Mark',
          role: :integrator,
        },
        ebergeron: {
          name: 'Emilie Bergeron',
          company: ' Vox CG',
          role: :designer,
        },
        mpesant: {
          name: 'Mathieu Pesant',
          company: 'Cégep de Sainte-Foy',
          role: :integrator,
        },
        sbouchard: {
          name: 'Sylvain Bouchard',
          company: 'Savoir-faire Linux',
          role: :programmer,
        },
        ftomalty: {
          name: 'Fletcher Tomalty',
          company: nil,
          role: :programmer,
        },
        mysterious1: {
          name: 'Antoine Savignac',
          company: t('sections.folks.from_bordeau'),
          role: :integrator,
        },
      },
      reds: {
        abproulx: {
          name: 'Alexia B. Proulx',
          company: 'Cégep de Sainte-Foy',
          role: :integrator_e,
        },
        cmonchablon: {
          name: 'Cesar Monchablon',
          company: 'Cégep de Sainte-Foy',
          role: :designer,
        },
        dvanderwindt: {
          name: 'Damien Van Der Windt',
          company: 'Nurun',
          role: :integrator,
        },
        gesanderson: {
          name: 'Gregory Eric Sanderson',
          company: 'Avencall',
          role: :programmer,
        },
        jbourassa: {
          name: 'Jimmy Bourassa',
          company: 'Hookt Studios',
          role: :programmer,
        },
        mysterious2: {
          name: 'Benjamin Bort',
          company: t('sections.folks.from_bordeau'),
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
        graph.get_object("/#{ENV['FB_ALBUM_ID']}/photos?fields=picture,link,width,height")
      end
    end

    @hours = cache.fetch('commits', :expire_in => 60 * 60) do
      github = Github.new do |config|
        config.endpoint    = 'https://api.github.com'
        config.oauth_token = ENV['GITHUB_TOKEN']
        config.adapter     = :net_http
        config.ssl         = {:verify => false} if development?
      end
      @commits = github.repos.commits.all('ironweb', 'ironweb-live')
      @hours = []
      @commits.map! do |reponse|
        # require 'debugger'
        # debugger
        if reponse.commit.committer
          time = reponse.commit.committer.date
        else
          time = reponse.commit.author.date
        end
        hour = ((Time.parse(time).localtime - Time.now)/60/60).round * -1
        if @hours[hour].nil?
          @hours[hour] = 1
        else
          @hours[hour] = @hours[hour] + 1
        end
      end
      @hours
    end
    @commitsData = [{
      name: '',
      color: '#95b1bd',
      data: @hours.reverse
    }]
  end

  def rescue_array &block
    begin
      block.call
    rescue Exception => exception
      nil
    end
  end
end