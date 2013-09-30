# -*- coding: utf-8; -*-
# vim:set fileencoding=utf-8:

require 'checkmk/devicedetector'
require 'slop'

module CheckMK
  module DeviceDetector
    class Cli
      def run(argv = ARGV)
        parse_options_slop(argv)

        CheckMK::DeviceDetector::Config.load

        detector = CheckMK::DeviceDetector::Detector.new

        detector.parse_locations(ARGF.read)
        detector.detect_devices(CheckMK::DeviceDetector::Config.jobs)
        detector.detect_devices_properties(CheckMK::DeviceDetector::Config.jobs)

        detector.locations.each do |location|
          puts "#{location.name} #{location.ranges.join(" ")}: #{location.devices.size} devices"
          location.devices.each do |device|
            puts "  #{device.name}"
            puts "    hostname:  #{device.hostname}"
            puts "    ipaddress: #{device.ipaddress}"
            puts "    location:  #{device.location.name}"
            puts "    tags:      " + device.tags.to_h.to_a.map { |a| a[0].to_s == a[1].to_s ? a[0].to_s : "#{a[0]}:#{a[1]}" }.sort.join(' ')
          end
        end
      end

      def parse_options_slop(argv = ARGV)
        options = Slop.new help: true, multiple_switches: true

        options.banner <<-END
          Scans your network for devices and builds suitable configuration for
          CheckMK/WATO.

          Usage:
            #{$PROGRAM_NAME} [OPTIONS] [-l] RANGE-FILES

          STDIN is read if location file is '-' or omitted:
            #{$PROGRAM_NAME} [OPTIONS] < RANGE-FILE
            cat RANGE-FILES | #{$PROGRAM_NAME} [OPTIONS] [-r -]
            echo 'Local 192.168.0.0/24' | #{$PROGRAM_NAME} [OPTIONS] [-r -]

          Range files contain a name and the IP adress ranges to be scanned. Each line
          begins with the name followed by one or multiple IP address ranges. Name and
          range(s) are divided by whitespace. The ranges must conform to the nmap [1]
          target specifications.

          [1] http://nmap.org/book/man-target-specification.html

          The options listed below may be specified indifferent ways like shown in this
          examples:  -ca.rb  -c a.rb  -c=a.rb  --c a.rb  --c=a.rb
                     -config a.rb  -config=a.rb  --config a.rb  --config=a.rb
          END
          .gsub(/^          /, '')
        options.on('c=', 'config=', 'The configuration file(s) to use',
                   as: Array, default: ['config.rb'])
        options.on('j=', 'jobs=', 'The maximum number of jobs run in parallel',
                   as: Integer, default: 4)
        options.on('r=', 'ranges=', 'The file(s) containing ranges to be scanned',
                   as: Array, default: ['ranges.txt'])

        options.parse(argv)
        require 'pp' ; pp options.to_hash
        options
      end
    end
  end
end
