cask "occam" do
  version "1.2.0"
  sha256 "7f0011010ecff4b73da6c4f09845648539aee6f1d25a2295862e96eba592b123"

  url "https://github.com/mpalczew/occam/releases/download/v#{version}/Occam-#{version}-universal.zip"
  name "Occam"
  desc "Minimalist macOS app launcher"
  homepage "https://github.com/mpalczew/occam"

  depends_on macos: ">= :ventura"

  app "Occam.app"

  zap trash: [
    "~/Library/Preferences/com.occam.launcher.plist",
  ]
end
