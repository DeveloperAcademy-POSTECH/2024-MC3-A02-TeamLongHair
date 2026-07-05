#!/usr/bin/env ruby
# Usage: ruby scripts/xcodeproj_add.rb <project.pbxproj> <group_name> <file.swift>
# 파일은 이미 해당 그룹의 폴더에 디스크로 존재해야 한다.
require 'securerandom'

pbxproj, group_name, file_name = ARGV
abort "usage: xcodeproj_add.rb <pbxproj> <group_name> <file.swift>" unless pbxproj && group_name && file_name

text = File.read(pbxproj)
abort "#{file_name} already in project" if text.include?("/* #{file_name} */")

uuid_ref = SecureRandom.hex(12).upcase
uuid_build = SecureRandom.hex(12).upcase

build_line = "\t\t#{uuid_build} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{uuid_ref} /* #{file_name} */; };\n"
text.sub!(/(\/\* Begin PBXBuildFile section \*\/\n)/) { $1 + build_line } or abort "PBXBuildFile section not found"

ref_line = "\t\t#{uuid_ref} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_name}; sourceTree = \"<group>\"; };\n"
text.sub!(/(\/\* Begin PBXFileReference section \*\/\n)/) { $1 + ref_line } or abort "PBXFileReference section not found"

group_re = /(\/\* #{Regexp.escape(group_name)} \*\/ = \{\s*isa = PBXGroup;\s*children = \(\n)/
text.sub!(group_re) { $1 + "\t\t\t\t#{uuid_ref} /* #{file_name} */,\n" } or abort "group #{group_name} not found"

src_re = /(isa = PBXSourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \(\n)/
text.sub!(src_re) { $1 + "\t\t\t\t#{uuid_build} /* #{file_name} in Sources */,\n" } or abort "Sources build phase not found"

File.write(pbxproj, text)
puts "Added #{file_name} to group #{group_name}"
