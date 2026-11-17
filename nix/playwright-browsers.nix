# The browser builds Playwright downloads with `npx playwright install
# chromium`, fetched ahead of time so the e2e check runs without network.
# Point PLAYWRIGHT_BROWSERS_PATH at the result.
#
# Playwright only launches the exact browser revision it was released with,
# and nixpkgs' playwright-driver lags the version in package-lock.json, so
# these builds are pinned here. When package-lock.json moves to another
# Playwright version, take the revisions and browser version from that
# version's playwright-core/browsers.json and update the hashes.
{
  lib,
  stdenv,
  fetchzip,
  linkFarm,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  expat,
  glib,
  libgbm,
  libgcc,
  libxkbcommon,
  nspr,
  nss,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxrandr,
  # The Playwright version package-lock.json resolves.
  lockedVersion,
}:
let
  playwrightVersion = "1.65.0";
  chromiumRevision = "1254";
  chromiumVersion = "158.0.8127.18";
  ffmpegRevision = "1013";
  cdn = "https://cdn.playwright.dev";

  chromium-headless-shell = stdenv.mkDerivation {
    pname = "playwright-chromium-headless-shell";
    version = chromiumVersion;
    src = fetchzip {
      name = "chrome-headless-shell-linux64-${chromiumVersion}";
      url = "${cdn}/builds/cft/${chromiumVersion}/linux64/chrome-headless-shell-linux64.zip";
      stripRoot = false;
      hash = "sha256-CJB0HhSaPLj84F9wPn633mn4JzR6IyJcW4QK21YSMnY=";
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      alsa-lib
      at-spi2-atk
      expat
      glib
      libgbm
      libgcc.lib
      libxkbcommon
      nspr
      nss
      libxcomposite
      libxdamage
      libxfixes
      libxrandr
    ];
    installPhase = ''
      cp -R . $out
    '';
  };

  ffmpeg = fetchzip {
    name = "playwright-ffmpeg-${ffmpegRevision}";
    url = "${cdn}/dbazure/download/playwright/builds/ffmpeg/${ffmpegRevision}/ffmpeg-linux.zip";
    stripRoot = false;
    hash = "sha256-5+WbgtmcKkTaSurejqzkkglNI/0dW7ePxbltOeCiakI=";
  };
in
lib.throwIfNot (lockedVersion == playwrightVersion)
  "package-lock.json resolves Playwright ${lockedVersion}, but nix/playwright-browsers.nix fetches the browsers for ${playwrightVersion}; update it."
  (
    linkFarm "playwright-browsers-${playwrightVersion}" {
      "chromium_headless_shell-${chromiumRevision}" = chromium-headless-shell;
      "ffmpeg-${ffmpegRevision}" = ffmpeg;
    }
  )
