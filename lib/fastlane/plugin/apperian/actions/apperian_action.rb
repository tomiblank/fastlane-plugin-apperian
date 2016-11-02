module Fastlane
  module Actions
    class ApperianAction < Action
      DEBUG = true
      def self.run(params)
        if DEBUG
          UI.message("The apperian plugin is working!")
          UI.message(" api_url: #{params[:api_url]}")
          UI.message(" email: #{params[:email]}")
          UI.message(" password: #{params[:password]}")
          UI.message(" app_identifier: #{params[:app_identifier]}")
          UI.message(" ipa: #{params[:ipa]}")
          UI.message(" author: #{params[:author]}")
          UI.message(" version: #{params[:version]}")
          UI.message(" version_notes: #{params[:version_notes]}")
        end

        api_url = params[:api_url]
        email = params[:email]
        password = params[:password]
        app_identifier = params[:app_identifier]
        ipa = params[:ipa]
        author = params[:author]
        version = params[:version]
        version_notes = params[:version_notes]

        # step 1: authenticate
        UI.message("1. Authenticate")
        token = authenticate(api_url, email, password)

        # step 2: find app
        UI.message("2. Find app")
        appID = find_app(api_url, app_identifier, token)
        if DEBUG
          UI.message("Found app:")
          UI.message(appID)
        end
        
        transactionID = ""
        fileUploadURL = ""
        # step 3a: create app

        # step 3b: update app
        UI.message("3b. Update app")
        result = update_app(api_url, appID, token) # return array [0] = transactionID, [1] = fileUploadURL
        transactionID = result[0]
        fileUploadURL = result[1]

        # step 4: upload file
        UI.message("4. Upload file")
        fileID = upload_file(fileUploadURL, ipa)

        # step 5: publish app
        UI.message("5. Publish app")
        result = publish_app(api_url, fileID, token, transactionID, author, version, version_notes)

        # arr = create_app(api_url, token)
        # if DEBUG 
        #   UI.message(arr)
        # end
        
      end

      # returns token
      def self.authenticate(api_url, email, password) 
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse(api_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/js"
        request.body = JSON.dump({
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.user.authenticateuser",
          "params" => {
            "email" => email,
            "password" => password
          }
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if DEBUG 
          UI.message(response.code)
          UI.message(response.body)        
        end
        
        json = JSON.parse(response.body)
        token = json["result"]["token"]
        return token
      end

      def self.find_app(api_url, app_identifier, token)
        # get the list of apps 
        data = list_apps(api_url, token)
        result = ""

        data['result']['applications'].each do |app|
          if app['bundleId'] == app_identifier
            result = app['ID']
            break
          end
        end

        return result
      end

      def self.list_apps(api_url, token)
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse(api_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/js"
        request.body = JSON.dump({
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.getlist",
          "params" => {
            "token" => token
          }
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.create_app(api_url, token)
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse(api_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/js"
        request.body = JSON.dump({
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.create",
          "params" => {
            "token" => token
          }
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        transactionID = json["result"]["transactionID"]
        fileUploadURL = json["result"]["fileUploadURL"]
        return transactionID, fileUploadURL
      end

      def self.update_app(api_url, appID, token)
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse(api_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/js"
        request.body = JSON.dump({
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.update",
          "params" => {
            "appID" => appID,
            "token" => token
          }
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        transactionID = json["result"]["transactionID"]
        fileUploadURL = json["result"]["fileUploadURL"]
        return transactionID, fileUploadURL
      end

      def self.publish_app(api_url, fileID, token, transactionID, author, version, version_notes)
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse(api_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/js"
        request.body = JSON.dump({
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.publish",
          "params" => {
            "EASEmetadata" => {
              "author" => author,
              "name" => "app name",
              "shortdescription" => "short description",
              "longdescription" => "long description",
              "version" => version,
              "versionNotes" => version_notes
            },
            "files" => {
              "application" => fileID
            },
            "token" => token,
            "transactionID" => transactionID
          }
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        status = json["result"]["status"]
        appID = json["result"]["appID"]
        return status, appID
      end

      def self.upload_file(upload_url, file_path)
        require 'rest-client'

        response = RestClient.post upload_url, :LUuploadFile => File.new(file_path, 'rb')

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        fileID = json["fileID"]
        return fileID

      end

      def self.description
        "Allows to upload your app file to Apperian"
      end

      def self.authors
        ["Thomas Blank"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Detailled description will follow soon"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_url,
                                  env_name: "APPERIAN_API_URL",
                               description: "The API URL to the Apperian API host",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :email,
                                  env_name: "APPERIAN_EMAIL",
                               description: "Your email address to authenticate yourself with the Apperian API host",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :password,
                                  env_name: "APPERIAN_PASSWORD",
                               description: "Your password to authenticate yourself with the Apperian API host",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "APPERIAN_APP_IDENTIFIER",
                               description: "The identifier of your app",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                  env_name: "APPERIAN_IPA",
                               description: "The path to your IPA file",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :author,
                                  env_name: "APPERIAN_AUTHOR",
                               description: "Author of the app",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :version,
                                  env_name: "APPERIAN_VERSION",
                               description: "Version number",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :version_notes,
                                  env_name: "APPERIAN_VERSION_NOTES",
                               description: "Version notes",
                                  optional: false,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Platforms.md
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
