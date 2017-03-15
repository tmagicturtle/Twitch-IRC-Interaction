#===========================================================================================
# ** Twitch IRC Interaction
# * Version: 0.7
# * https://github.com/tmagicturtle/
#-------------------------------------------------------------------------------------------
# 
# This script allows streamers to automate certain functions within their Twitch chats.
# It was designed to be easily expandable to perform new tasks.
#
# Current functions include:
#  * Automatically connects to Twitch chat
#  * Tracks which subscribers have an active coupon (Revlo)
#  * Will refund half the value of their next redemption if coupon is active (Revlo)
#  * Whispers Jackbox roomcode (or other information) upon redeeming a specific Revlo reward
#  * Responds to !vikavolt
#  * Upon redemption of Pay Day, generates a random number between 1 and 15 and grants points to all (Revlo)
#
# Installation:
#  As a Ruby script, this requires Ruby to be installed on the user's machine.
#  It has been tested on Ruby 1.9.2p180.
#  Once Ruby is installed, simply run from the command line:
#     ruby (path_to_this_file)
#
# The user specified in the configuration must be a moderator in the chat.
# The user must also be a supermoderator in Revlo in order to reward coins (optional).
#
# Special thanks to Elodicolo
#
#===========================================================================================
# CONFIGURATION
#===========================================================================================
$channel = 'elodicolo'
$room_code = '0000'
$reward_title = 'Jackbox Jumpbox'
$username = 'user'
$oauth = 'oauth:000000000000000000000000000000'
      # get OAuth key from https://twitchapps.com/tmi/
#===========================================================================================
# END OF CONFIGURATION - EDIT BELOW ONLY IF YOU KNOW WHAT YOU ARE DOING
#===========================================================================================
require 'socket'
Thread.abort_on_exception = true
$user_array = []

class Twitch
 attr_reader :running, :socket 
 def initialize
  @running = false
  @socket = nil
 end
 
 def send(message='')
  @socket.puts(message)
 end
 
 def run
  puts 'Attempting to connect...'
  @socket = TCPSocket.new('irc.chat.twitch.tv', 6667)
  @running = true
  puts 'Connected.'
  @socket.puts("PASS #{$oauth}")
  @socket.puts("NICK #{$username}")
  @socket.puts("JOIN ##{$channel}")
  puts ''
  puts "Logged in as #{$username} in ##{$channel}."
  puts ''
  puts "Enter 'help' to see available options."
  puts "Enter 'set CODE' to change the active room code."
  Thread.start do
   while (@running) do
    ready = IO.select([@socket])
    ready[0].each do |s|
     line = s.gets		
	 match = line.match(/^:revlobot!.+ PRIVMSG .+ :(.+) spent ([0-9]+) points to redeem (.+)$/)
	 if match
	  user,value = $1, $2
	  redeemed = $3[1..-4]
	  $user_array.push(user) if redeemed == "Coupon"
	  if value.to_i > 0 && $user_array.include?(user)
	   @socket.puts("PRIVMSG ##{$channel} :!bonus #{user} #{value / 2}")
	   $user_array.delete(user)
	  end
	  if redeemed == $reward_title
	   @socket.puts("PRIVMSG ##{$channel} :/w #{user} #{$room_code}")
	   puts "#{true_user} has been sent a room code #{$room_code} for Jackbox."
	  end
	  if redeemed = "Pay Day"
		amount = rand(15)+1
		@socket.puts("PRIVMSG ##{$channel} :!bonusall #{amount}")
		puts "All users have gained #{amount} Revlo points from Pay Day."
	  end
	 end
	 match = line.match(/^:(.+)!.+ PRIVMSG .+ :!vikavolt.+$/)
	 if match
	  user = $1
	  @socket.puts("PRIVMSG ##{$channel} :/color HotPink")
	  sleep(0.1)
	  @socket.puts("PRIVMSG ##{$channel} :/me did a thing to #{user}")
	  sleep(0.1)
	  @socket.puts("PRIVMSG ##{$channel} :/color VioletBlue")
	 end
    end
   end
  end
 end
 
 def stop
  @running = false
 end
 
 def commands(c='')
  puts ''
  puts "Enter 'help' to see available options."
  puts "Enter 'set CODE' to change the active room code."
  puts "Enter 'stop' to quit. Aliases: 'exit' and 'quit'."
 end
 
end

bot = Twitch.new
bot.run

while (bot.running) do
 command = gets.chomp
 if command == "quit"
  bot.stop
 elsif command == "stop"
  bot.stop
 elsif command == "exit"
  bot.stop
 elsif command == "help"
  bot.commands
 elsif command.match(/^set (.+)$/)
  $room_code = $1
  puts "Room code set to #{$1}."
 else
  bot.send(command)
 end
end
puts 'Chat bot shut down.'
