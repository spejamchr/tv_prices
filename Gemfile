# frozen_string_literal: true

source 'https://rubygems.org' do
  git_source(:github) do |repo_name|
    repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
    "https://github.com/#{repo_name}.git"
  end

  gem 'nokogiri'
  gem 'parallel'

  ruby '~> 2.6'
end
