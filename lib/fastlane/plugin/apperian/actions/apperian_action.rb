module Fastlane
  module Actions
    class ApperianAction < Action
      DEBUG = false
      def self.run(params)
        if DEBUG
          UI.message("The apperian plugin is working!")
          UI.message(" api_url: #{params[:api_url]}")
          UI.message(" email: #{params[:email]}")
          UI.message(" password: #{params[:password]}")
          UI.message(" app_identifier: #{params[:app_identifier]}")
          UI.message(" ipa: #{params[:ipa]}")
          UI.message(" app_name: #{params[:app_name]}")
          UI.message(" author: #{params[:author]}")
          UI.message(" short_description: #{params[:short_description]}")
          UI.message(" long_description: #{params[:long_description]}")
          UI.message(" version: #{params[:version]}")
          UI.message(" version_notes: #{params[:version_notes]}")
        end

        api_url = params[:api_url]
        email = params[:email]
        password = params[:password]
        app_identifier = params[:app_identifier]
        ipa = params[:ipa]
        app_name = params[:app_name]
        author = params[:author]
        short_description = params[:short_description]
        long_description = params[:long_description]
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
        
        # step 3: create or update app
        transactionID = ""
        fileUploadURL = ""

        if appID == "" then
          # step 3a: create app
          UI.message("3a. Create app")
          result = create_app(api_url, token) # return array [0] = transactionID, [1] = fileUploadURL
          transactionID = result[0]
          fileUploadURL = result[1]
        else 
          # step 3b: update app
          UI.message("3b. Update app")
          result = update_app(api_url, appID, token) # return array [0] = transactionID, [1] = fileUploadURL
          transactionID = result[0]
          fileUploadURL = result[1]
        end

        # step 4: upload file
        UI.message("4. Upload file")
        fileID = upload_file(fileUploadURL, ipa)

        # step 5: publish app
        UI.message("5. Publish app")
        result = publish_app(api_url, fileID, token, transactionID, app_name, author, short_description, long_description, version, version_notes)
        
      end


      def self.authenticate(api_url, email, password)
        require 'rest-client'
        require 'json'

        body = {
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.user.authenticateuser",
          "params" => {
            "email" => email,
            "password" => password
          }
        }
        
        response = RestClient.post(api_url, body.to_json, {content_type: :json, accept: :json})
        
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
        require 'rest-client'
        require 'json'

        body = {
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.getlist",
          "params" => {
            "token" => token
          }
        }
        
        response = RestClient.post(api_url, body.to_json, {content_type: :json, accept: :json})

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.create_app(api_url, token)
        require 'rest-client'
        require 'json'

        body = {
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.create",
          "params" => {
            "token" => token
          }
        }
        
        response = RestClient.post(api_url, body.to_json, {content_type: :json, accept: :json})

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
        require 'rest-client'
        require 'json'

        body = {
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.update",
          "params" => {
            "appID" => appID,
            "token" => token
          }
        }
        
        response = RestClient.post(api_url, body.to_json, {content_type: :json, accept: :json})

        if DEBUG
          UI.message(response.code)
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        transactionID = json["result"]["transactionID"]
        fileUploadURL = json["result"]["fileUploadURL"]
        return transactionID, fileUploadURL
      end

      def self.publish_app(api_url, fileID, token, transactionID, app_name, author, short_description, long_description, version, version_notes)
        require 'rest-client'
        require 'json'

        body = {
          "id" => 1,
          "apiVersion" => "1.0",
          "jsonrpc" => "2.0",
          "method" => "com.apperian.eas.apps.publish",
          "params" => {
            "EASEmetadata" => {
              "author" => author,
              "name" => app_name,
              "shortdescription" => short_description,
              "longdescription" => long_description,
              "version" => version,
              "versionNotes" => version_notes
            },
            "files" => {
              "application" => fileID
            },
            "token" => token,
            "transactionID" => transactionID
          }
        }
        
        response = RestClient.post(api_url, body.to_json, {content_type: :json, accept: :json})

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
        require 'json'

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
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No Apperian API URl given, check https://help.apperian.com/display/pub/Using+the+Publishing+API for options and pass using `api_url: 'https://easesvc.apperian.com/ease.interface.php'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :email,
                                  env_name: "APPERIAN_EMAIL",
                               description: "Your email address to authenticate yourself with the Apperian API host",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No email for Apperian authentication given, pass using `email: 'me@example.com'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :password,
                                  env_name: "APPERIAN_PASSWORD",
                               description: "Your password to authenticate yourself with the Apperian API host",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No password for Apperian authentication given, pass using `password: 'secret'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "APPERIAN_APP_IDENTIFIER",
                               description: "The identifier of your app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app identifier given, pass using `app_identifier: 'com.example.app'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :ipa,
                                  env_name: "APPERIAN_IPA",
                               description: "The path to your IPA file",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Could not find IPA file, pass using `ipa: '/path/to/file.ipa'`") unless File.exist?(value)
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                  env_name: "APPERIAN_APP_NAME",
                               description: "The name of your app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app name given, pass using `app_name: 'My sample app'`") unless value and !value.empty?
                                              UI.user_error!("app_name: maximum characters allowed: 30") unless value.length <= 30
                                            end),

          FastlaneCore::ConfigItem.new(key: :author,
                                  env_name: "APPERIAN_AUTHOR",
                               description: "Author of the app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No author given, pass using `author: 'Bob'`") unless value and !value.empty?
                                              UI.user_error!("author: maximum characters allowed: 150") unless value.length <= 150
                                            end),

          FastlaneCore::ConfigItem.new(key: :short_description,
                                  env_name: "APPERIAN_SHORT_DESCRIPTION",
                               description: "Short description",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No short description given, pass using `short_description: 'This is what my app does'`") unless value and !value.empty?
                                              UI.user_error!("short_description: maximum characters allowed: 100") unless value.length <= 100
                                            end),

          FastlaneCore::ConfigItem.new(key: :long_description,
                                  env_name: "APPERIAN_LONG_DESCRIPTION",
                               description: "Long description",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No long description given, pass using `long_description: 'Detailled description of my app'`") unless value and !value.empty?
                                              UI.user_error!("long_description: maximum characters allowed: 10'000'") unless value.length <= 10000
                                            end),

          FastlaneCore::ConfigItem.new(key: :version,
                                  env_name: "APPERIAN_VERSION",
                               description: "Version number",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No version given, pass using `version: '1.0.2'`") unless value and !value.empty?
                                              UI.user_error!("version: maximum characters allowed: 21") unless value.length <= 21
                                            end),

          FastlaneCore::ConfigItem.new(key: :version_notes,
                                  env_name: "APPERIAN_VERSION_NOTES",
                               description: "Version notes",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No version notes given, pass using `version_notes: 'New version available'`") unless value and !value.empty?
                                              UI.user_error!("version_notes: maximum characters allowed: 1500") unless value.length <= 1500
                                            end)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Platforms.md

        [:ios].include?(platform)
      end
    end
  end
end
