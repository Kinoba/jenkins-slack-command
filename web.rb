# frozen_string_literal: true

require 'sinatra'
require 'rest-client'
require 'json'
require 'slack-notifier'

get '/' do
  'This is a thing'
end

post '/' do
  # Verify all environment variables are set
  return [403, 'No slack token setup'] unless slack_token = ENV['SLACK_TOKEN']
  return [403, 'No jenkins url setup'] unless jenkins_url = ENV['JENKINS_URL']
  return [403, 'No jenkins base url setup'] unless jenkins_base_url = ENV['JENKINS_BASE_URL']
  return [403, 'No jenkins token setup'] unless jenkins_token = ENV['JENKINS_TOKEN']

  # Verify slack token matches environment variable
  return [401, 'Not authorized for this command'] unless slack_token == params['token']

  # Split command text
  text_parts = params['text'].split(' ')

  # Split command text - job
  job = text_parts[0]

  # Split command text - parameters
  parameters = []
  if text_parts.size > 1
    all_params = text_parts[1..-1]
    all_params.each do |p|
      p_thing = p.split('=')
      parameters << { name: p_thing[0], value: p_thing[1] }
    end
  end

  # Get Jenkins crumb
  resp = RestClient.get("#{jenkins_url}/crumbIssuer/api/json")
  resp_json = JSON.parse(resp.body)
  crumb = resp_json['crumb']

  # Jenkins url
  jenkins_job_url = "#{jenkins_url}/job/#{job}"

  # Get next jenkins job build number
  resp = RestClient.get "#{jenkins_job_url}/api/json"
  resp_json = JSON.parse(resp.body)
  next_build_number = resp_json['nextBuildNumber']

  # Make jenkins request
  json = JSON.generate(parameter: parameters)
  RestClient.post "#{jenkins_job_url}/build?token=#{jenkins_token}", { json: json }, 'Jenkins-Crumb': crumb.to_s

  # Build url
  build_url = "#{jenkins_base_url}/job/#{job}/#{next_build_number}/console"

  slack_webhook_url = ENV['SLACK_WEBHOOK_URL']
  if slack_webhook_url
    notifier = Slack::Notifier.new slack_webhook_url, username: 'jenkins'
    notifier.ping "Started job '#{job}' - #{build_url}", icon_url: 'https://wiki.jenkins.io/download/attachments/2916393/logo.png?version=1&modificationDate=1302753947000&api=v2'
  end

  build_url
end
