#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'

# Definitions
def fetch_policyfiles(current_dir)
  puts '**** Fetching policyfiles ****'
  policies = []
  Dir.foreach("#{current_dir}/../../policyfiles") do |policy|
    next unless policy.end_with?('.rb')
    policies.push(File.basename(policy, '.*'))
  end
  policies.sort
end

def update_lock_files(policies, current_dir)
  puts '**** Updating policyfile locks ****'
  FileUtils.cd("#{current_dir}/../../policyfiles")
  $stdout.sync = true
  policies.each do |policy|
    puts "**** Updating #{policy}.lock.json file ****"
    cmd = File.exist?("#{policy}.lock.json") ? "chef update #{policy}.rb" : "chef install #{policy}.rb"
    system(cmd)
  end
end

# Main
current_dir = File.dirname(__FILE__)
policyfiles = fetch_policyfiles(current_dir).sort.freeze
options = {}

# parse arguments
ARGV.options do |opts|
  begin
    opts.on('-p', '--policy_name NAME1,NAME2', Array, "(Required) One or more policy_names (#{policyfiles.dup.push('all').sort.join(', ')})") do |v|
      options[:policies] = v.include?('all') ? policyfiles : v
    end
    opts.on_tail('-h', '--help', 'Prints this help') do
      puts opts
      exit
    end
    opts.parse!
  rescue
    puts "\nError in options found!!!\n"
    puts opts
    exit(1)
  end
end

update_lock_files(options[:policies], current_dir)
