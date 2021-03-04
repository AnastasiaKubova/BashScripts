#!/usr/bin/env ruby

# Use this script for downloading assemblies from jCenter and local signing with GPG key.
# Usage: ./download-and-sign-archives.sh

require 'json'
require 'fileutils'
require 'open-uri'

# Prepare URL constants.
ORG_NAME="YOUR ORG NAME"
REPO_NAME="YOUR REPO NAME"
PACKAGE_NAME="YOUR/PACKAGE/NAME"

DOMEN="https://bintray.com/#{ORG_NAME}/#{REPO_NAME}/download_file?file_path=#{PACKAGE_NAME}"
DOCS_URL_CONST="#{DOMEN}/%s/%s/%s-%s-javadoc.jar"
SOURCES_URL_CONST="#{DOMEN}/%s/%s/%s-%s-sources.jar"
POM_URL_CONST="#{DOMEN}/%s/%s/%s-%s.pom"
AAR_URL_CONST="#{DOMEN}/%s/%s/%s-%s.aar"
MAVEN_META_URL_CONST="#{DOMEN}/%s/maven-metadata.xml"

# Contains info about versions.
REPO_URL_CONST="https://api.bintray.com/packages/#{ORG_NAME}/#{REPO_NAME}/%s"

# File names.
DOCS_FILE_NAME="%s-%s-javadoc.jar"
SOURCE_FILE_NAME="%s-%s-sources.jar"
POM_FILE_NAME="%s-%s.pom"
AAR_FILE_NAME="%s-%s.aar"
MAVEN_META_FILE_NAME="maven-metadata.xml"

PATH_TO_GPG_FILE="PATH TO GPG KEY"
PASSWORD_GPG="PASSWORD FOR GPG KEY"
USERNAME="USER NAME FOR GPG KEY"

MODULES = ["MODULE NAME 1", "MODULE NAME 2", "MODULE NAME 3 ..."]

def encriptFile(fileName) 
    puts "Encripting file #{fileName} from current folder..."

    # Encript file with GPG key.
    cmd  = `gpg --secret-keyring "#{PATH_TO_GPG_FILE}" --passphrase "#{PASSWORD_GPG}" --batch --yes --encrypt --armor --recipient "#{USERNAME}" #{fileName} ` 
end

def encriptFilesInFolder(targetDir) 
    puts "Encripting files from #{targetDir}..."

    # Encript files with GPG key.
    cmd  = `cd #{targetDir} && ls | gpg --secret-keyring "#{PATH_TO_GPG_FILE}" --passphrase "#{PASSWORD_GPG}" --batch --yes --encrypt-files --encrypt --armor --recipient "#{USERNAME}" ` 
end

def downloadAndEncriptMetaDataFile(packageName, targetDirName) 

    # Prepare URL and target file.
    targetUrl = MAVEN_META_URL_CONST % [packageName]
    targetFileName = "#{targetDirName}/#{MAVEN_META_FILE_NAME}"

    # Download file.
    download = open("#{targetUrl}")
    IO.copy_stream(download, "#{targetFileName}")

    # Encript file.
    encriptFile(targetFileName)
end

def downloadSource(url, filename, targetDirName, packageName, ver)

    # Create target dir if not exist
    dirname = File.dirname(targetDirName)
    unless File.directory?(targetDirName)
        FileUtils.mkdir_p(targetDirName)
    end

    # Prepare URL and target file.
    targetUrl=url % [packageName, ver, packageName, ver]
    puts targetUrl
    targetFilename=filename % [packageName, ver]
    targetPath="#{targetDirName}/#{targetFilename}"

    # Download file.
    download = open("#{targetUrl}")
    IO.copy_stream(download, "#{targetPath}")
end

def downloadSources(packageName)

    # Download file with versions.
    repoUrl = REPO_URL_CONST % packageName
    result = `/usr/bin/curl --insecure #{repoUrl}`

    # Get versions from the file.
    data = JSON.parse(result)

    #Download artifacts for each version.
    data["versions"].each do |ver| 
        puts "Downloading #{packageName} artifacts for the version #{ver}..."

        # Prepate target folder.
        targetDirName = "#{packageName}/#{ver}"

        # Download files.
        downloadSource(DOCS_URL_CONST, DOCS_FILE_NAME, targetDirName, packageName, ver)
        downloadSource(SOURCES_URL_CONST, SOURCE_FILE_NAME, targetDirName, packageName, ver)
        downloadSource(POM_URL_CONST, POM_FILE_NAME, targetDirName, packageName, ver)
        downloadSource(AAR_URL_CONST, AAR_FILE_NAME, targetDirName, packageName, ver)

        # Encript files in target folder.
        encriptFilesInFolder(targetDirName)
    end
end

MODULES.each do |m|
    downloadSources(m)
    downloadAndEncriptMetaDataFile(m, m)
end

# JFYI: manual deploy.
# https://central.sonatype.org/pages/manual-staging-bundle-creation-and-deployment.html
