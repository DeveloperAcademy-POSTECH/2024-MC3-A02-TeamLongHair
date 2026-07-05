#!/usr/bin/env ruby
# Usage: ruby scripts/xcodeproj_remove.rb <project.pbxproj> <file.swift>
# 주의: 파일명이 등장하는 모든 라인을 제거하므로 프로젝트 내에서 유일한 파일명에만 사용.
pbxproj, file_name = ARGV
abort "usage: xcodeproj_remove.rb <pbxproj> <file.swift>" unless pbxproj && file_name

text = File.read(pbxproj)
kept = text.lines.reject { |l| l.include?(file_name) }
removed = text.lines.size - kept.size
abort "#{file_name} not found in project" if removed.zero?
File.write(pbxproj, kept.join)
puts "Removed #{removed} lines for #{file_name}"
