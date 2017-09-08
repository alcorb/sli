#!/usr/bin/env ruby
require 'yaml'
require 'slop'
require 'slack-ruby-client'
require 'fileutils'

@config_path = "#{Dir.home}/.config/sli/config.yml"

def configure
  puts "Sli is not configured."
  puts "To configure, plase visit https://api.slack.com/custom-integrations/legacy-tokens and create Legacy token."
  puts "My token:"
  token = gets.chomp
  config = {token: token}
  FileUtils.mkdir_p File.dirname(@config_path)  
  File.write(@config_path, config.to_yaml)
end

unless File.file?(@config_path)
  configure()
end

sli_config = YAML.load_file(@config_path)
if (sli_config.nil? || sli_config[:token].blank?)
  configure()
  sli_config = YAML.load_file(@config_path)
end

Slack.configure do |config|
    config.token = sli_config[:token]
end

opts = Slop.parse ARGV do |o|
    o.bool '--send', '-s', 'send file command'
    o.bool '--message', '-m', 'send plain text message command'
    o.bool '--logout', '-l', 'clear config'
    o.string '--channel', '-c', 'specify channel without # or @'
end

if(opts.logout?)
  FileUtils.rm(@config_path)  
  exit
end

if(opts.message?)
  client = Slack::Web::Client.new
  client.auth_test
  client.chat_postMessage(channel: "#{opts[:channel]}", text: opts.arguments.join(' '), as_user: true)
  exit
end

if(opts.send?)
  puts opts[:channel]
  client = Slack::Web::Client.new
  client.auth_test
  client.files_upload(
    channels: "#{opts[:channel]}",
    as_user: true,
    file: Faraday::UploadIO.new(opts.arguments[0],"*/*"),
    filename: File.basename(opts.arguments[0])
  )
  exit
end

puts opts