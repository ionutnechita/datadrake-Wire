require 'awesome_print'
require 'singleton'
require 'sinatra/base'

$config = {}

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
			case name
				when 'create'
					
				#	Web.instance.sinatra.put(@uri) do
				#		$resources[request.path].create( request , response , params)
				#	end
				when 'read'
                                #        Web.instance.sinatra.get(@uri) do 
                                #                $resources[request.path].readAll( params )
                                #        end
				#	Web.instance.sinatra.get(@uri + "/:id") do
				#		$resources[request.path].read( request, response, params )
				#	end
				when 'update'
				#	@update.each do |uri, proc|
				#		Web.instance.sinatra.post(@uri + uri) do 
                                #                       $resources[request.path].instance_eval( &proc )
                                #                end
                                #        end
				when 'delete'
				#	@delete.each do |uri, proc|
				#		Web.instance.sinatra.delete(@uri + uri) do 
                                #                        $resources[request.path].instance_eval( &proc )
                                #
			        #	        end
                                #	end
			end
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
			@sinatra.get("/:app/:resource") do | a , r |
				if( $config[a] != nil ) then
					if( $config[a][:resources][r] != nil ) then
						if( $config[a][:resources][r][:actions].include?("read") ) then
							"I can read all!"
						else
							"Not Allowed"
						end
					else
						"Resource Undefined"
					end
				else
					"App Undefined"
				end
			end
			@sinatra.get("/:app/:resource/:id") do | a , r , i |
				if( $config[a] != nil ) then
					if( $config[a][:resources][r] != nil ) then
						if( $config[a][:resources][r][:actions].include?("read") ) then
							"I can read item #{i}!"
						else
							"Not Allowed"
						end
					else
						"Resource Undefined"
					end
				else
					"App Undefined"	
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
