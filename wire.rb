require 'awesome_print'
require 'singleton'
require 'sinatra/base'

$config = {}

class Sinatra::Base
	def prepare( appName , resourceName )
		hash = {:failure => false}
		app = $config[appName]
		if( app != nil ) then
			hash[:app] = app
			resource = app[:resources][resourceName]
			if( resource != nil ) then
				hash[:resource] = resource
				actions = resource[:actions]
				hash[:actions] = actions
			else
				hash[:message] = "Resource Undefined"
				hash[:failure] = true
			end
			type = app[:type]
			if( type != nil ) then
				hash[:controller] = type
			else
				hash[:message] = "Application type Not Specified"
				hash[:failure] = true
			end
		else
			hash[:message] = "App Undefined"
			hash[:failure] = true
		end
		hash
	end	
end

class Wire

	module App

		def app( baseURI , &block)
			$config[baseURI] = {:resources => {}}
			@currentURI = baseURI
			puts "Starting App at: #{baseURI}"
			puts "Setting up resources..."
			Docile.dsl_eval( self, &block )
		end

		def type( type )
			$config[@currentURI][:type] = type
		end

		def app_info( uri , config )
			puts "\t#{config[:type]} URI: #{uri}"

			puts "\n\tResources:"
			config[:resources].each do |uri, config|
				resource_info( uri , config )

			end

			puts "\n"
		end
	end

	module Resource

		def resource( uri , &block )
			$config[@currentURI][:resources][uri] = {:actions => []}
			@currentResource = uri
			puts "Starting Resource At: #{@currentURI + uri}"
			puts "Creating actions..."
			Docile.dsl_eval( self , &block )
		end

		def action( name )
			puts "Enabling Action: #{name}"
			$config[@currentURI][:resources][@currentResource][:actions] << name 
		end

		def resource_info( uri , config )
			puts "\t\tResource URI: #{uri}"
			puts "\t\tActions Allowed:"
			config[:actions].each do |a,v|
				puts "\t\t\t#{a}"
			end
			puts "\n"
		end
	end

	class Closet
		include Wire::App
		include Wire::Resource

		def initialize
			@sinatra = Sinatra.new

			## Create One or More
			@sinatra.put("/:app/:resource") do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( context[:actions].include?("create") ) then
						context[:controller].create( context , request , response )
					else
						"Operation not allowed"
					end

				else
					context[:message]
				end
			end

			## Read all
			@sinatra.get("/:app/:resource") do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( context[:actions].include?("read") ) then
						context[:controller].readAll( context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Read One
			@sinatra.get("/:app/:resource/:id") do | a , r , i |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( context[:actions].include?("read") ) then
						context[:controller].read( i , context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Update One or More
			@sinatra.post("/:app/:resource" ) do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( context[:actions].include?("update") ) then
						context[:controller].update( context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Delete One
			@sinatra.delete("/:app/:resource/:id") do | a , r , i |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( context[:actions].include?("delete") ) then
						context[:controller].delete( i , context , request , response )
					else
						"Operation not permitted"
					end
				else
					context[:message]
				end
			end
		end

		def build( &block )
			puts "Starting Up Wire..."
			puts "Starting Apps..."
			Docile.dsl_eval( self , &block )
		end

		def info
			puts "Wire Instance Info\n\nApps:"
			$config.each do |uri , config|
				app_info( uri , config )
			end
		end

		def run
			ap $config
			puts @sinatra.routes
			@sinatra.run!
		end
	end
end
