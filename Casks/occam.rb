cask "occam" do
  version "1.0.0"
  sha256 "9c4be910c03edc1ed29e5942ca62aa357fc1519c5231bbecc4a6d01966c65531"

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
