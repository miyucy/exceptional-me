require "date"
require "json"
require "pp"
require "stringio"
require "time"
require "zlib"

class Exceptions
  class << self
    def save(json)
      occurred_at = json.delete "occurred_at"
      if occurred_at and occurred_at.size > 0
        json["occurred_at"] = Time.parse occurred_at
      end

      collection.insert(json)
    end

    def find(*args)
      collection.find(*args)
    end

    def collection
      db.collection("exceptions")
    end

    def db
      @db ||= Mongo::MongoClient.new.db("exceptional-me")
    end
  end
end

class Wrap
  METHOD = "POST".freeze
  PATH   = "/api/errors".freeze
  VER5   = "protocol_version=5".freeze
  VER6   = "protocol_version=6".freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    if trap? env
      dump env["REQUEST_URI"], env["rack.input"]
      [200, {}, [""]]
    else
      @app.call env
    end
  end

  def dump(uri, input)
    input.rewind
    data = input.read
    json = case
           when uri.include?(VER5)
             Zlib::Inflate.inflate data
           when uri.include?(VER6)
             Zlib::GzipReader.wrap(StringIO.new(data)){ |gz| gz.read }
           else
             return
           end
    Exceptions.save JSON.parse(json)["exception"]
  end

  def trap?(env)
    ((env["REQUEST_METHOD"] == METHOD) and
     (env["REQUEST_PATH"] == PATH or env["PATH_INFO"] == PATH))
  end
end

class App < Sinatra::Base
  enable :logging, :method_override

  get "/" do
    limit = (params[:per_page] || 50).to_i
    skip  = ((params[:page] || 1).to_i - 1) * limit
    @exceptions = Exceptions.find({}, skip: skip, limit: limit, sort: [['occurred_at', :desc]]).to_a
    erb :index
  end

  delete "/:id" do
    id = BSON::ObjectId.from_string(params["id"])
    Exceptions.collection.remove("_id" => id)
    status 200
  end
end
