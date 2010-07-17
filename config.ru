#!/usr/bin/env rackup
require 'sinatra/base'
require 'linkeddata'

module Datagraph
  class Blog < Sinatra::Base
    FILES = %w(robots.txt favicon.ico favicon.gif)

    use Rack::Static, :urls => FILES.map { |f| "/#{f}" }, :root => ::File.dirname(__FILE__)
    set :views, ::File.dirname(__FILE__) + '/.templates'

    get('/') { "Hello, world!\n" }
  end
end

run Datagraph::Blog
