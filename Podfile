# platform : Mac, '8.0'

source 'https://github.com/RayWang1991/WRParsingBasic'

def wrEarleyParser_pods

  # pod 'AVOSCloudCrashReporting','3.3.4'
  pod 'WRParsingBasic', :path => ‘../../../WRParsingComponent/WRParsingBasic'

end

target 'WREarleyParser' do
  wrEarleyParser_pods
end

post_install do |installer|
        `find Pods -regex 'Pods/pop.*\\.h' -print0 | xargs -0 sed -i '' 's/\\(<\\)pop\\/\\(.*\\)\\(>\\)/\\"\\2\\"/'`
end
