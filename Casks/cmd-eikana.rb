cask "cmd-eikana" do
  version "2.5.1"
  sha256 "e5ca70981e97bd5747fbd997be373976504116aacfdbd67cf844e9ec4e54403b"

  url "https://github.com/dominion525/cmd-eikana/releases/download/v#{version}/cmd-eikana-v#{version}-arm64.zip"
  name "Eikana"
  name "⌘英かな"
  homepage "https://github.com/dominion525/cmd-eikana"

  depends_on :macos

  app "⌘英かな.app"

  zap trash: "~/Library/Preferences/io.github.dominion525.cmd-eikana.plist"
end
