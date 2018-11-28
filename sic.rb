#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'xcodeproj'
require 'set'
require 'optparse'
require 'ostruct'


options = OpenStruct.new
options.includeTestTargets = false
optionParser = OptionParser.new do |opt|
    opt.on('--workspace WORKSPACE_PATH') { |o| options[:workspacePath] = o }
    opt.on('--include-test-targets') { |o| options[:includeTestTargets] = o }
end
optionParser.parse!

if options.workspacePath == nil
    puts "You must provide a workspace."
    puts optionParser.help()
    exit 1
end

workspacePath = options.workspacePath
includeTestTargets = options.includeTestTargets

workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspacePath)

projects = workspace.file_references.map do |file|
    Xcodeproj::Project.open(file.absolute_path(File.dirname(workspacePath)))
end

@allTargets = Set[]
for project in projects
    if File.basename(project.path) != "Pods.xcodeproj"
        @allTargets += project.targets
    end
end


def linkedFrameworksForTarget(target)
    if !target.respond_to?(:frameworks_build_phase)
        return []
    end
    target.frameworks_build_phase.file_display_names.map do |f| File.basename(f, ".framework") end
end

def filesForTarget(target)
    if !target.respond_to?(:source_build_phase)
        return []
    end
    target.source_build_phase.files.map do |f|
       f.file_ref.real_path
    end
end

def importsInFiles(files)
    imports = Set[]
    files.each do |f|
        if File.extname(f) == ".swift"
            File.open f do |file|
                file.each do |line|
                    if line =~ /(?:\@testable\s+)?import\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\s+)?([^\.\n]*)/
                        imports.add($1)
                    end
                end
            end
        end
    end
    imports.to_a
end

def check(target)
    files = filesForTarget(target)
    imports = importsInFiles(files)
    linkedFrameworks = linkedFrameworksForTarget(target)
    puts target
    imports.each do |import|
        allTargets_str = @allTargets.map do |t| t.to_s end
        if !linkedFrameworks.include?(import) && allTargets_str.include?(import)
            puts("    #{import}")
        end
    end
end

for project in projects
    for target in project.targets
        allTargets_str = @allTargets.map do |t| t.to_s end
        if allTargets_str.include?(target.to_s) && (includeTestTargets || !target.to_s.end_with?("Tests"))
            check(target)
        end
    end
end
