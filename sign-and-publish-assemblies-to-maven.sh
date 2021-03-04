#!/usr/bin/env ruby

# Use this script for signing assemblies in jCenter and publishing assemblies from jCenter to maven.
# Usage: ./sign-and-publish-assemblies-to-maven.sh

require 'uri'
require 'net/http'
require 'net/https'
require 'json'

# Main contains.
ORG_NAME="YOUR ORG NAME"
REPO_NAME="YOUR REPO NAME"
PACKAGE_NAME="YOUR/PACKAGE/NAME"

SONATYPE_USERNAME="YOUR SONATYPE USER NAME"
SONATYPE_PASSWORD="YOUR SONATYPE PASSWORD"

JCENTER_USERNAME="YOUR JCENTER NAME"
JCENTER_PASSWORD="YOUR JCENTER TOKEN"
GPG_PHRASE="YOUR GPG PASSWORD"

# Contains info about versions.
REPO_URL_CONST="https://api.bintray.com/packages/#{ORG_NAME}/#{REPO_NAME}/%s"
REPO_TARGET_URL_FOR_SIGN="https://api.bintray.com/gpg/#{ORG_NAME}/#{REPO_NAME}/%s/versions/%s"
REPO_SYNC_URL="https://api.bintray.com/maven_central_sync/#{ORG_NAME}/#{REPO_NAME}/%s/versions/%s"
MODULES = ["MODULE NAME 1", "MODULE NAME 2", "MODULE NAME 3 ..."]

def signJcenterAssemblies(packageName, ver)

    # Prepared URL
    targetUrl = REPO_TARGET_URL_FOR_SIGN % [packageName, ver]
    uri = URI.parse(targetUrl)

    puts "Request for SIGN #{packageName} assemblies with the version #{ver}..."

    # Create a request.
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        req = Net::HTTP::Post.new(uri, initheader = {'X-GPG-PASSPHRASE' => GPG_PHRASE})
        req['Content-Type'] = 'application/json'
        req.basic_auth JCENTER_USERNAME, JCENTER_PASSWORD

        # Perfomed request.
        response = http.request req # Net::HTTPResponse object
        puts "Response #{response.code} #{response.message}: #{response.body}"
    end
end

def syncWithMavenCenter(packageName, ver)
    
    # Prepared URL
    targetUrl = REPO_SYNC_URL % [packageName, ver]
    uri = URI.parse(targetUrl)

    puts "Request for SYNC #{packageName} assemblies with the version #{ver}..."

    boby = {
        "username" => SONATYPE_USERNAME,
        "password" => SONATYPE_PASSWORD,
        "close" => "1" # Change this value to 0 if you want to deply assemblies manually.
    }.to_json

    # Create a request.
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :read_timeout => 500) do |http|
        req = Net::HTTP::Post.new(uri, initheader = {'X-GPG-PASSPHRASE' => GPG_PHRASE})
        req['Content-Type'] = 'application/json'
        req.basic_auth JCENTER_USERNAME, JCENTER_PASSWORD
        req.body = boby

        # Perfomed request.
        response = http.request req # Net::HTTPResponse object
        puts "Response #{response.code} #{response.message}: #{response.body}"
    end
end

def signAndSyncAssemblies()
    MODULES.each do |m|
        
        # Download file with versions.
        repoUrl = REPO_URL_CONST % m
        result = `/usr/bin/curl --insecure #{repoUrl}`

        # Get versions from the file.
        data = JSON.parse(result)

        # Signing artifacts for each version.
        data["versions"].each do |ver| 
            puts "Perform #{m} and #{ver}"
            signJcenterAssemblies(m, ver)
            syncWithMavenCenter(m, ver)
        end
    end
end

def totalOfModiles() 
    count = 0
    MODULES.each do |m|

        # Download file with versions.
        repoUrl = REPO_URL_CONST % m
        result = `/usr/bin/curl --insecure #{repoUrl}`

        # Get versions from the file.
        data = JSON.parse(result)
        count += data["versions"].length()
    end
    count = count * 4
    puts "Total modules: #{count}"
end

signAndSyncAssemblies()


