require 'yaml'

module Partyhat
  class Util
    # Convert an experience value to a level
    # Uses a formula from somewhere.
    # TODO: Add source for formula.
    def self.experience_to_level experience
      levels = get_levels
      level = 126
      experience = 0 if experience < 0
      while !levels[level].nil? && levels[level] > experience
        level -= 1
      end
      return level
    end

    # Convert a level value into experience
    # Uses a formula from somewhere.
    # FIXME: This is not accurate, check partyhat_util_spec results
    # TODO: Add source for formula.
    def self.level_to_experience level
      return get_levels[level]
    end

    # get the array of level experiences from the levels.yaml data file
    def self.get_levels
      YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'data/levels.yml'))
    end

    # Abbreviate a small or large number into compressed form
    # Usage:
    # Partyhat::Util.abbreviate_number(55_500) => "55K"
    # as seen all over the game. e.g. "5K"
    def self.shorten_number number
      divider = 1
      suffix  = nil
      if number >= 1_000_000_000
        divider = 1_000_000_000
        suffix = 'B'
      elsif number >= 1_000_000
        divider = 1_000_000
        suffix = 'M'
      elsif number >= 1_000
        divider = 1_000
        suffix = 'K'
      else
        divider = 1
        suffix = 'GP'
        return (number.to_i / divider.to_i).to_s + suffix
      end
      (number / divider.to_f).round(1).to_s + suffix
    end

    # De-abbreviate the already compressed number with the
    # abbreviate_number method.
    # Note:
    # Values might not stay the same if abbreviated
    # and then deabbreviated
    def self.parse_number string
      multiplier = 1
      string = string.upcase
      ending = string[-1,1].upcase
      case ending
        when 'B' then multiplier = 1_000_000_000
        when 'M' then multiplier = 1_000_000
        when 'K' then multiplier = 1_000
      end
      (string.to_f * (multiplier || 1)).round(1)
    end

    # Fetch a remote page and return it
    # If you pass in only one URL, direct source will be returneds
    # If you pass in multiple URLs, a hash will be returned with url indexes
    def self.fetch_remote urls
      urls = [urls] unless urls.is_a?(Array)
      responses = {}
      m = Curl::Multi.new
      urls.reject.each do |url|
        responses[url] = ""
        c = Curl::Easy.new(url) do|curl|
          curl.follow_location = true
          curl.on_body do |data|
            responses[url] << data
            data.size
          end
        end
        m.add(c)
      end
      m.perform

      if responses.size > 1
        responses
      else
        responses[urls.pop]
      end
    end
  end
end