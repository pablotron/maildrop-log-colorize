#!/usr/bin/env ruby

#####################################################################
#                                                                   #
# maildrop-log-colorize.rb - maildrop log colorizer.                #
#                                                                   #
# by Paul Duncan <pabs@pablotron.org>                               #
# http://pablotron.org/                                             #
#                                                                   #
# Usage:                                                            #
#   $ tail -f path/to/maildrop.log | maildrop-logcolorize.rb        #
#       or                                                          #
#   $ maildrop-log-colorize.rb path/to/maildrop.log                 #
#                                                                   #
#####################################################################

module Maildrop
  class LogColorizer
    MAILDIR_REGEX = %r{^/home/pabs/mail/}

    # lookup table for various items
    CONFIG = {
      'strip' => {
        'file' => proc { |fn| fn.gsub(MAILDIR_REGEX, '') },
      },

      'colors' => {
        # arrival date
        'date' => 'light_green',

        # message source
        'from' => 'cyan',

        # message subject
        'subj' => 'light_cyan',

        # message size
        'size' => 'light_blue',

        # destination folder
        'file' => [
          { 're' => /spam/, 'color' => 'yellow' },
          { 'color' => 'white' },
        ],
      }
    }
    
    PALETTE = {
      'black'         => "\033[0;30m", 
      'blue'          => "\033[0;34m", 
      'green'         => "\033[0;32m", 
      'cyan'          => "\033[0;36m", 
      'red'           => "\033[0;31m", 
      'purple'        => "\033[0;35m", 
      'brown'         => "\033[0;33m", 
      'light_grey'    => "\033[0;37m", 
      'dark_grey'     => "\033[1;30m", 
      'light_blue'    => "\033[1;34m", 
      'light_green'   => "\033[1;32m", 
      'light_cyan'    => "\033[1;36m", 
      'light_red'     => "\033[1;31m", 
      'light_purple'  => "\033[1;35m", 
      'yellow'        => "\033[1;33m", 
      'white'         => "\033[1;37m", 
      'nothing'       => "\033[0m", 
    }

    def self.run(args)
      # determine input method
      if args.size > 0 && args.first != '-'
        fh = IO.popen("tail -f --follow=name #{ARGV.shift}", 'r')
      else
        fh = $stdin
      end

      new(fh).run
    end

    def initialize(fh)
      @fh = fh
    end

    def run
      while line = @fh.gets
        # strip trailing whitespace
        line = line.strip

        case line
        when /^(Date|From|Subj): (.*)$/
          label, val = $1, $2

          # get color
          key = label.downcase
          c = color_for(key, val)

          # map value
          if s = CONFIG['strip'][key]
            val = s.call(val)
          end

          # reformat line
          line = '%s: %s%s%s' % [
            label,
            PALETTE[c || 'nothing'],
            val,
            PALETTE['nothing'],
          ]
        when /^File: (.*?)(\s+)\((\d+)\)/
          fn, ws, sz = $1, $2, $3
          c = [color_for('file', fn), color_for('size', sz)]

          # map destination value
          if s = CONFIG['strip']['file']
            fn_len = fn.size
            fn = s.call(fn)

            # add whitespace
            ws += ' ' * (fn_len - fn.size) if fn_len > fn.size
          end

          # map file size
          if s = CONFIG['strip']['size']
            sz = s.call(sz)
          end

          # reformat line
          line = 'File: %s%s%s%s%s(%s)%s' % [
            PALETTE[c[0] || 'nothing'],
            fn,
            PALETTE['nothing'],

            ws,

            PALETTE[c[1] || 'nothing'],
            sz,
            PALETTE['nothing'],
          ]
        end

        # print line to standard output
        puts line
      end
    end

    private

    def color_for(key, val)
      r = nil

      if r = CONFIG['colors'][key]
        if r.kind_of?(Array)
          if r = r.find { |e| !e['re'] || e['re'].match(val) }
            r = r['color']
          end
        end
      end

      r
    end
  end
end

Maildrop::LogColorizer.run(ARGV) if __FILE__ == $0
