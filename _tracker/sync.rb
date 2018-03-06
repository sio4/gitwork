#!/usr/bin/env ruby

require 'bundler/setup'
require 'colorize'
require 'json'
require 'optparse'

file = File.read('repos.json')
wd = 'working'

hash = JSON.parse(file)

options = {}
OptionParser.new do |opts|
  opts.banner = "usage: sync.rb [options]"
  opts.on("-n", "--new", "Newly added repository only") do |v|
    options[:new] = v
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:new] == true
  puts "running in new repository only mode..."
end


unless File.exist?("#{wd}")
  Dir.mkdir "#{wd}"
end

for e in hash
  origin = e['origin']
  forked = e['forked']
  proj = File.basename(forked).sub('.git','')

  if options[:new] == true and File.exist?("#{wd}/#{proj}")
    next
  end

  puts ""
  puts ">>> processing #{proj} (#{forked})...".blue
  if origin == ""
    puts ">>> origin is blank. maybe break sign. abort processing.".magenta
    break
  end

  # clone it if there is no cloned one.
  unless File.exist?("#{wd}/#{proj}")
    ret = system("cd #{wd}; git clone " + forked)
    unless ret
      puts ">>> cloning failed for #{proj}".red
      next
    end

    ret = system("cd #{wd}/#{proj}; git remote add upstream #{origin}")
    unless ret
      puts ">>> cloned but cannot add upstream for #{proj}".red
      next
    end
    puts ">>> cloning and adding upstream completed for #{proj}.".yellow
  end

  # preparing upstream (fetching...)
  ret = system("cd #{wd}/#{proj}; git fetch upstream master")
  unless ret
    puts ">>> fetching upstream failed for #{forked}".red
    next
  end

  # merging into upstream.
  ret = system("cd #{wd}/#{proj}; git branch upstream")
  ret = system("cd #{wd}/#{proj}; git checkout upstream")
  unless ret
    puts ">>> fetched but checking out upstream failed for #{proj}".red
    next
  end

  output = `cd #{wd}/#{proj}; git merge upstream/master`
  unless $?.success?
    puts ">>> checked out but merging failed for #{proj}".red
    next
  end
  puts ">>> checking out and merging upstream completed.".green

  if output.strip == 'Already up-to-date.'
    puts ">>> the branch already up-to-date!".yellow
  else
    ret = system("cd #{wd}/#{proj}; git push")
    unless ret
      puts ">>> pushing upstream failed for #{proj}".red
      next
    end
    puts ">>> pushing upstream completed: #{proj}".green
  end

  # update master...
  ret = system("cd #{wd}/#{proj}; git checkout master")
  unless ret
    puts ">>> checking out master failed for #{proj}".red
    next
  end

  output = `cd #{wd}/#{proj}; git merge upstream`
  unless $?.success?
    puts ">>> checked out but merging failed for #{proj}".red
    next
  end
  puts ">>> checking out and merging master completed.".green

  if output.strip == 'Already up-to-date.'
    puts ">>> the branch already up-to-date!".yellow
  else
    ret = system("cd #{wd}/#{proj}; git push")
    unless ret
      puts ">>> pushing master failed for #{proj}".red
      next
    end
    puts ">>> pushing master completed: #{proj}".green
  end

  puts ">>> syncing #{forked} completed".blue
end
