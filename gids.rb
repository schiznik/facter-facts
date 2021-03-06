require 'puppet'

#
# gids.rb
#
# This fact provides mapping between user logins and their GIDs as a Hash
#
# Usage: $::gids['root'] # => 0
#

Facter.add(:gids) do
  confine :kernel => :linux

  setcode do
    gids = {}

    #
    # Modern Linux distributions provide "/etc/passwd" in the following format:
    #
    #  root:x:0:0:root:/root:/bin/bash
    #  (...)
    #
    # Above line has the follwing fields separated by the ":" (colon):
    #
    #  <user name>:<password>:<user ID>:<group ID>:<comment>:<home directory>:<command shell>
    #
    # We only really care about "user name" and "user ID" fields.
    #

    #
    # We use "getent" binary first if possible to look-up what users are currently
    # available on system.  This is possibly due to an issue in Puppet "user" type
    # which causes Facter to delay every Puppet run substantially especially when
    # LDAP is in place to provide truth source about users etc ...
    #
    # In the unlikely event in which the "getent" binary is not available we simply
    # fall-back to using Puppet "user" type ...
    #

    if File.exists?('/usr/bin/getent')
      # We work-around an issue in Facter #10278 by forcing locale settings ...
      ENV['LC_ALL'] = 'C'

      Facter::Util::Resolution.exec('/usr/bin/getent passwd').each_line do |line|
        line.strip!
        user = line.split(':')
        gids[user[0]] = user[3].to_i
      end
    else
      Puppet::Type.type('user').instances.each do |user|
        instance = user.retrieve
        gids[user.name] = instance[user.property(:gid)].to_i
      end
    end

    gids
  end
end
