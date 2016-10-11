#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'

# Config
jira_board_id      = ""
jira_username      = ""
jira_password      = ""
jira_url           = ""

def getTasksForActiveSprint (jira_board_id, jira_username, jira_password, jira_url)
	tasks = 0
	
	sprintUri = URI("https://#{jira_url}/rest/agile/1.0/board/#{jira_board_id}/sprint?state=active")

	puts "... requesting #{sprintUri.request_uri}"
	
	Net::HTTP.start(sprintUri.host, sprintUri.port,
		:use_ssl     => sprintUri.scheme == 'https', 
		:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

		request = Net::HTTP::Get.new sprintUri.request_uri
		request.basic_auth jira_username, jira_password

		sprintResponse     = http.request request
		sprintResponseJson = JSON.parse(sprintResponse.body)

		sprintId  = sprintResponseJson['values'][0]['id'];  
	

		issuesUri = URI("https://#{jira_url}/rest/agile/1.0/sprint/#{sprintId}/issue")
		hadIssues = true
	  
		puts "... requesting #{issuesUri.request_uri}"
	  
		Net::HTTP.start(issuesUri.host, issuesUri.port,
			:use_ssl     => issuesUri.scheme == 'https', 
			:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

			request = Net::HTTP::Get.new issuesUri.request_uri
			request.basic_auth jira_username, jira_password

			issuesResponse = http.request request
			issuesResponseJson = JSON.parse(issuesResponse.body)

			tasks = issuesResponseJson['total'];
		end
	end
 
	puts "... tasks: #{tasks}"
 
	return tasks
end

#getTasksForActiveSprint(jira_board_id, jira_username, jira_password, jira_url)

SCHEDULER.every '5m', :first_in => 0 do |job|
	count = getTasksForActiveSprint(jira_board_id, jira_username, jira_password, jira_url)
 
	send_event('jira_tasks', current: count)
end