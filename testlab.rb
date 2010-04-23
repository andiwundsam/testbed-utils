#!/usr/bin/ruby
require 'optparse'

class ExpNode
   attr_accessor :name, :connect, :user, :host
   def initialize(name, args={})
      @name = name

      unless args.empty?
          args.each_pair { |k,v|
              self.send("#{k}=", v)
          }
      end
   end

   def connect_cmd
       case self.connect
        when nil:
            return []
        when :sudo
            return ["sudo su -"]
        when :ssh
            if self.user
                return [ "ssh #{self.user}@#{self.host}" ]
            else
                return [ "ssh #{self.host}" ]
            end
        else
            raise "Unknown connect type: you #{self.connect} may want to override connect_cmd()"
        end
   end
end

class ScreenSession
  def initialize(name)
	@name = name
  end

  def create
     ScreenSession.screen "-d", "-m", "-S", @name
  end

  def remoteCmd(window, cmd)
  	windowcmd window, "stuff", "#{cmd}\n"
  end

  def select(title)
  	cmd "select", title
  end
  
  def  createWindow(title)
  	cmd "screen", "-t", title
  end

  def quit
	cmd "quit"
  end

  def windowcmd(title, *cmd)
     args = [ "-S", @name, "-p", title, "-X" ] + cmd
     ScreenSession.screen *args
  end
  
  def cmd(*cmd)
     args = [ "-S", @name, "-X" ] + cmd
     ScreenSession.screen *args
  end

  def ScreenSession.screen(*args)
     args = args.unshift "screen"
     #screen needs some time 
     sys *args
     sleep 0.2
  end
end    

def sys(*args)
     puts "! #{args.inspect}"
     res = system *args
     raise "Error: #{$?}" unless res
end

class ExpOptions
   attr_accessor :sessionName, :expName, :policy, :expType
   def validate
      raise "Must give experiment type: --type direct|lib" unless expType
      raise "Unknown experiment type: direct|lib" unless expType == "direct" or expType == "lib"
      raise "Must give policy when type==lib" if expType == "lib" and policy.nil? 

      @policy ||= "Reject"
      @sessionName ||= "ehs_exp"
      @expName ||= ( expType == "direct" ? "direct" : "lib_#{policy}" )
    end

   def self.parse()
       res = ExpOptions.new()
       OptionParser.new do |opts|
           opts.on(:REQUIRED, "-tTYPE", "--type TYPE", "Experiment type: direct|lib") do |v|
	       res.expType = v
	   end
           opts.on(:REQUIRED, "-pPOLICY", "--policy POLICY", "Routed policy to use") do |v|
	       res.policy = v
	   end
           opts.on(:REQUIRED, "-sSESSION", "--session-name SESSION", "Screen session name to use") do |v|
	       res.sessionName = v
	   end
           opts.on(:REQUIRED, "-eEXPERIMENT", "--exp-name EXPERIMENT", "Experiment name to use") do |v|
	       res.expName = v
	   end
           # No argument, shows at tail.  This will print an options summary.
           # Try it and see!
           opts.on_tail("-h", "--help", "Show this message") do
             puts opts
             exit
           end
	end.parse!
	res.validate
 	return res	
    end
end

def makeResultsDir(expDir, experimentName)
    resultsDir = File.join(expDir, "results", experimentName)

    if File.exist?(resultsDir)
      index=1
      while(File.exist?(newDir="#{resultsDir}.#{index}"))
           index += 1
      end
      resultsDir=newDir
    end

    Dir.mkdir(resultsDir)
    return resultsDir
end
