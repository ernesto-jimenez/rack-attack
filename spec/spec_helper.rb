require "rubygems"
require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"
require "rack/test"
require 'active_support'
require 'action_dispatch'

# Load Journey for Rails 3.2
require 'journey' if ActionPack::VERSION::MAJOR == 3

require "rack/attack"

begin
  require 'pry'
rescue LoadError
  #nothing to do here
end

class MiniTest::Spec

  include Rack::Test::Methods

  after { Rack::Attack.clear! }

  def app
    Rack::Builder.new {
      use Rack::Attack
      map '/status' do
        run lambda {|env|
          code = env['PATH_INFO'][1..-1].to_i
          [code, {}, ["Status: #{code}"]]
        }
      end
      run lambda {|env| [200, {}, ['Hello World']]}
    }.to_app
  end

  def self.allow_ok_requests
    it "must allow ok requests" do
      get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'
      last_response.status.must_equal 200
      last_response.body.must_equal 'Hello World'
    end
  end

  def self.allow_failed_requests
    it "must allow failing requests" do
      get '/status/404', {}, 'REMOTE_ADDR' => '127.0.0.1'
      last_response.status.must_equal 404
      last_response.body.must_equal 'Status: 404'
    end

    it "must allow custom status requests" do
      get '/status/429', {}, 'REMOTE_ADDR' => '127.0.0.1'
      last_response.status.must_equal 429
      last_response.body.must_equal 'Status: 429'
    end
  end
end

class Minitest::SharedExamples < Module
  include Minitest::Spec::DSL
end
