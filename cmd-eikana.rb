cask "cmd-eikana" do
  version "2.4.2"
  sha256 "330739688aceed8940d6befd6eb2a2a40ce73a8b6e3a4d765271d629985b4623"

  url "https://github.com/dominion525/cmd-eikana/releases/download/v#{version}/cmd-eikana-v#{version}-arm64.zip"
  name "Eikana"
  name "⌘英かな"
  homepage "https://github.com/dominion525/cmd-eikana"

  depends_on :macos

  app "⌘英かな.app"

  zap trash: "~/Library/Preferences/io.github.dominion525.cmd-eikana.plist"
end
