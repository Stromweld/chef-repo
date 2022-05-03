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

def upload_policyfiles(policy_groups, policy_names, current_dir)
  $stdout.sync = true
  FileUtils.cd("#{current_dir}/../../policyfiles")
  policy_names.each do |policy|
    puts "**** Uploading policy #{policy} to chef-server ****"
    policy_groups.each do |group|
      system("chef push #{group} #{policy}.rb")
    end
  end
end

def fetch_chef_server_policies
  puts '**** Fetching chef-server policies ****'
  srv_policies = []
  list = `knife list -R /policies`.split
  list.each do |policy|
    next unless policy.end_with?('.json')
    policy_name = File.basename(policy, '.*').split('-').first
    srv_policies.push(policy_name) unless srv_policies.include?(policy_name)
  end
  srv_policies.sort.uniq
end

def fetch_chef_server_policy_groups
  puts '**** Fething chef-server policy_groups ****'
  srv_policy_groups = []
  list = `knife list -R /policy_groups`.split
  list.each do |group|
    next unless group.end_with?('.json')
    srv_policy_groups.push(File.basename(group, '.*'))
  end
  srv_policy_groups.sort
end

def verify_values(srv_values, values)
  if values.nil?
    raise
  else
    values.each do |test|
      next if srv_values.include?(test)
      puts "#{test} doesn't exist on the chef server current values are:"
      puts srv_values.join(' ')
      puts "\nDo you want to create new value #{test}? (y/n):\n"
      if $stdin.gets.chomp.downcase == 'y'
        next
      else
        raise
      end
    end
  end
end

# Main
current_dir = File.dirname(__FILE__)
srv_groups = nil
srv_policies = nil
policyfiles = nil

parallel = [
  Thread.new { srv_groups = fetch_chef_server_policy_groups.sort.freeze },
  Thread.new { srv_policies = fetch_chef_server_policies.sort.freeze },
  Thread.new { policyfiles = fetch_policyfiles(current_dir).sort.freeze },
]
parallel.each(&:join)

options = {}

# parse arguments
ARGV.options do |opts|
  begin
    opts.on('-g', '--policy_group NAME1,NAME2', Array, "(Required) One or more policy_group names (#{srv_groups.dup.push('all').sort.join(', ')})") do |v|
      options[:groups] = v.include?('all') ? srv_groups : v
    end
    opts.on('-p', '--policy_name NAME1,NAME2', Array, "(Required) One or more policy_names (#{policyfiles.dup.push('all').sort.join(', ')})") do |v|
      options[:policies] = v.include?('all') ? policyfiles : v
    end
    opts.on_tail('-h', '--help', 'Prints this help') do
      puts opts
      exit
    end
    opts.parse!
    verify_values(srv_groups, options[:groups])
    verify_values(srv_policies, options[:policies])
  rescue
    puts "\nError in options found!!!\n"
    puts opts
    exit(1)
  end
end

upload_policyfiles(options[:groups], options[:policies], current_dir)
