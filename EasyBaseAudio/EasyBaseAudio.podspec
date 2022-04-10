
Pod::Spec.new do |spec|
  spec.name         = "EasyBaseAudio"
  spec.version      = "1.0.0"
  spec.summary      = "This framework handless the everything about Audio"
  spec.description  = "I hope This Framework will you to code easy, It take time less than"

  spec.homepage     = "https://github.com/haiphan5289/EasyBaseAudio"
  spec.license      = "MIT"
  spec.author             = { "haiphan5289" => "haiphan5289@gmail.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://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@github.com/haiphan5289/EasyBaseAudio.git", :tag => spec.version.to_s }
  spec.source_files  = "EasyBaseAudio/**/*.{swift}"
  spec.swift_version = "5.0"

end
