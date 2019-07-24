# SwiftImportChecker

Checks that frameworks that have been imported in source files (eg `import MyFramework`) are linked to the target.

It ignores Pods as CocoaPods handles that itself. It also ignores System frameworks as those are automatically linked.

Why? So that Xcode knows what order to build things in the New Swift Build System with Parallelize Build turned on, and you can avoid unobvious errors like this https://stackoverflow.com/questions/30355133/swift-framework-umbrella-header-h-not-found

## Usage

`./sic.rb --workspace ~/MyApp.xcworkspace [--includes-test-targets]`

Outputs:

    MyApp
       MyFramework1
    MyFramework1
       MyFramework2
       MyFramework4
    MyFramework3
    MyFramework4

This shows that you need to add `MyFramework1` to Linked Frameworks and Libraries in `MyApp`, and add `MyFramework2` and `MyFramework4` to `MyFramework1`. Whereas as `MyFramework3` and `MyFramework4` are fine and you don't need to add anything to their Linked Frameworks and Libraries sections. 

## To Do

* Check for targets that link to frameworks but don't import them in any source files
* Make it a gem
* Automatically add the missing linked frameworks. Seems to be tricky across projects in a workspace.
