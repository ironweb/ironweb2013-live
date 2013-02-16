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
  end

  assets {
    serve '/',     from: 'assets/public'
    serve '/fonts',     from: 'assets/fonts'
    serve '/js',     from: 'assets/js'
    serve '/css',    from: 'assets/css'
    serve '/img', from: 'assets/img'

    js :app, '/js/app.js', [
      '/js/main.js'
    ]
    css :app, '/css/application.css', [
      '/css/reset.css',
      '/css/styles.css',
    ]

    js_compression  :jsmin      # Optional
    css_compression :simple       # Optional
  }
  {:fr => '/', :en => '/en'}.each do |locale, path|    
    get path do
      I18n.locale = locale
      I18n.reload! if development?
      @channels = [:ironweb_greens, :ironweb_reds]
      params[:channel] ||= @channels.sample

      @folks = {
        contestants: {
          alefrancois: {
            name: 'Alexandre Lefrançois',
            company: 'Image de Mark',
            role: :integrator,
          },
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
          ebergeron: {
            name: 'Emilie Bergeron',
            company: ' Vox CG',
            role: :designer,
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
          mpesant: {
            name: 'Mathieu Pesant',
            company: 'Cégep de Sainte-Foy',
            role: :integrator,
          },
          ftomalty: {
            name: 'Fletcher Tomalty',
            company: nil,
            role: :programmer,
          },
          sbouchard: {
            name: 'Sylvain Bouchard',
            company: 'Savoir-faire Linux',
            role: :programmer,
          },
        }
      }

      erb :index
    end
  end
end