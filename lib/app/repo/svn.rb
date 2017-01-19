##
# Copyright 2017 Bryan T. Meyers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
##

require 'nori'
require 'fileutils'
require_relative '../repo'

module Repo
  # Repo::SVN is a connector for svnserve
  # @author Bryan T. Meyers
  module SVN
    extend Repo

    # Force Nori to convert tag names to Symbols
    @@nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

    # Make a new SVN repo
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @return [Integer] status code
    def self.do_create_file(path, repo)
      `svnadmin create #{path}/#{repo}`
      if $?.exitstatus != 0
        500
      else
        200
      end
    end

    # Read a single file
    # @param [String] rev the revision number to access
    # @param [String] web the subdirectory for web content
    # @param [String] user the username for connecting to SVN
    # @param [String] pass the password for connecting to SVN
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @return [String] the file
    def self.do_read_file(rev, web, user, pass, path, repo, id)
      options = "--username #{user} --password #{pass}"
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        body = `svn cat #{options} -r #{rev} 'svn://localhost/#{repo}/#{id}'`
      else
        body = `svn cat #{options} -r #{rev} 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      if $?.success?
        body
      else
        500
      end
    end

    # Read a directory listing
    # @param [String] web the subdirectory for web content
    # @param [String] user the username for connecting to SVN
    # @param [String] pass the password for connecting to SVN
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @return [Array] the directory listing
    def self.do_read_listing(web, user, pass, path, repo, id = nil)
      options = "--username #{user} --password #{pass}"
      if web.nil?
        if id.nil?
          list = `svn list #{options} --xml 'svn://localhost/#{repo}'`
        else
          list = `svn list #{options} --xml 'svn://localhost/#{repo}/#{id}'`
        end
      else
        if id.nil?
          list = `svn list #{options} --xml 'svn://localhost/#{repo}/#{web}'`
        else
          list = `svn list #{options} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
        end
      end
      unless $?.exitstatus == 0
        return 404
      end
      list = @@nori.parse(list)
      list[:lists][:list][:entry]
    end

    # Read Metadata for a single file
    # @param [String] rev the revision number to access
    # @param [String] web the subdirectory for web content
    # @param [String] user the username for connecting to SVN
    # @param [String] pass the password for connecting to SVN
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @return [Hash] the metadata
    def self.do_read_info(rev, web, user, pass, path, repo, id)
      options = "--username #{user} --password #{pass}"
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        info = `svn info #{options} -r #{rev} --xml 'svn://localhost/#{repo}/#{id}'`
      else
        info = `svn info #{options} -r #{rev} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      unless $?.exitstatus == 0
        return 404
      end
      info = @@nori.parse(info)
      info[:info][:entry]
    end

    # Get a file's MIME type
    # @param [String] rev the revision number to access
    # @param [String] web the subdirectory for web content
    # @param [String] user the username for connecting to SVN
    # @param [String] pass the password for connecting to SVN
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @return [String] the MIME type
    def self.do_read_mime(rev, web, user, pass, path, repo, id)
      options = "--username #{user} --password #{pass}"
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        mime = `svn propget #{options} -r #{rev} --xml svn:mime-type 'svn://localhost/#{repo}/#{id}'`
      else
        mime = `svn propget #{options} -r #{rev} --xml svn:mime-type 'svn://localhost/#{repo}/#{web}/#{id}'`
      end
      unless $?.success?
        return 500
      end
      mime = @@nori.parse(mime)
      if mime[:properties].nil?
        'application/octet-stream'
      else
        mime[:properties][:target][:property]
      end
    end

    # Update a single file
    # @param [String] web the subdirectory for web content
    # @param [String] user the username for connecting to SVN
    # @param [String] pass the password for connecting to SVN
    # @param [String] path the path to the repositories
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @param [String] content the updated file
    # @param [String] message the commit message
    # @param [String] mime the mime-type to set
    # @param [String] username the Author of this change
    # @return [Integer] status code
    def self.do_update_file(web, user, pass, path, repo, id, content, message, mime, username)
      options = "--username #{user} --password #{pass}"
      status  = 500
      id      = id.split('/')
      id.pop
      id = id.join('/')
      if web.nil?
        repo_path = "/tmp/svn/#{repo}/#{id}"
      else
        repo_path = "/tmp/svn/#{repo}/#{web}/#{id}"
      end
      unless Dir.exist? repo_path
        FileUtils.mkdir_p(repo_path)
      end

      `svn checkout #{options} 'svn://localhost/#{repo}' '/tmp/svn/#{repo}'`
      id = CGI.unescape(id)
      if $?.exitstatus == 0
        id = id.split('/')
        id.pop
        id = id.join('/')
        if web.nil?
          file_path = "/tmp/svn/#{repo}/#{id}"
        else
          file_path = "/tmp/svn/#{repo}/#{web}/#{id}"
        end

        unless Dir.exist? file_path
          FileUtils.mkdir_p(file_path)
        end

        file = File.open(file_path, 'w+')
        file.syswrite(content)
        file.close
        `svn add --force "/tmp/svn/#{repo}/*"`
        `svn propset svn:mime-type "#{mime}" "#{file_path}"`
        `svn commit #{options} -m "#{message}" "/tmp/svn/#{repo}"`
        if $?.exitstatus == 0
          status = 200
        end
        `svn propset #{options} --revprop -r HEAD svn:author '#{username}' "/tmp/svn/#{repo}"`
      end
      `rm -R '/tmp/svn/#{repo}'`
      status
    end
  end
end