require 'rubygems'
require 'bundler/setup'
Bundler.require
require File.dirname(File.expand_path __FILE__) + '/app'

use Wrap
run App
