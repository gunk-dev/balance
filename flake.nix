{
  description = "BALANCE — a web-based tracking app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        version = "0.1.0";
        src = ./.;

        # Fetched once and shared by the package and every npm check.
        npmDeps = pkgs.fetchNpmDeps {
          name = "balance-${version}-npm-deps";
          inherit src;
          hash = "sha256-X0z0MHFjkFqA/g+hprfd9JojAn4rv+DQl3hGwJH3eoo=";
        };

        balance = pkgs.buildNpmPackage {
          pname = "balance";
          inherit version src npmDeps;

          buildPhase = ''
            runHook preBuild
            npm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/{client/dist,server/dist,node_modules}
            cp -r client/dist/* $out/client/dist/
            cp -r server/dist/* $out/server/dist/
            cp -r node_modules $out/
            cp package.json $out/
            cp -r server/package.json $out/server/
            runHook postInstall
          '';
        };

        # A check run in the installed npm workspace, on the Node version CI
        # uses. Its output is empty unless installPhase keeps something.
        npmCheck =
          name: attrs:
          pkgs.buildNpmPackage (
            {
              pname = "balance-${name}";
              inherit version src npmDeps;
              nodejs = pkgs.nodejs_22;
              dontNpmInstall = true;
              installPhase = "touch $out";
            }
            // attrs
          );

        playwrightBrowsers = pkgs.callPackage ./nix/playwright-browsers.nix {
          lockedVersion =
            (lib.importJSON ./package-lock.json).packages."node_modules/playwright-core".version;
        };
      in
      {
        # Every test CI runs on a pull request, runnable offline with
        # `nix build .#checks.x86_64-linux.<name>`.
        checks = lib.optionalAttrs (system == "x86_64-linux") {
          build = balance;

          lint = npmCheck "lint" {
            buildPhase = "npm run lint";
          };

          e2e = npmCheck "e2e" {
            CI = "1";
            PLAYWRIGHT_BROWSERS_PATH = playwrightBrowsers;
            FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
            buildPhase = "npm run test:e2e";
            # The screenshots the specs take, as CI uploads them.
            installPhase = "cp -r client/test-results $out";
          };

          nixfmt =
            pkgs.runCommand "balance-nixfmt"
              {
                nativeBuildInputs = [ pkgs.nixfmt ];
                src = lib.fileset.toSource {
                  root = ./.;
                  fileset = lib.fileset.fileFilter (file: file.hasExt "nix") ./.;
                };
              }
              ''
                cd $src
                find . -name "*.nix" -exec nixfmt --check {} +
                touch $out
              '';

          zizmor =
            pkgs.runCommand "balance-zizmor"
              {
                nativeBuildInputs = [ pkgs.zizmor ];
                src = lib.fileset.toSource {
                  root = ./.;
                  fileset = ./.github;
                };
              }
              ''
                cd $src
                zizmor . --no-online-audits
                touch $out
              '';
        };

        packages = {
          default = balance;

          oci-image = pkgs.dockerTools.buildLayeredImage {
            name = "balance";
            tag = "latest";
            contents = [
              pkgs.nodejs_22
              pkgs.cacert
            ];
            extraCommands = ''
              mkdir -p app/client app/server
              cp -r ${balance}/client/dist app/client/dist
              cp -r ${balance}/server/dist app/server/dist
              cp -r ${balance}/node_modules app/node_modules
              cp ${balance}/package.json app/package.json
              cp ${balance}/server/package.json app/server/package.json
            '';
            config = {
              Cmd = [
                "${pkgs.nodejs_22}/bin/node"
                "/app/server/dist/index.js"
              ];
              Env = [
                "NODE_ENV=production"
                "PORT=8080"
              ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
              WorkingDir = "/app";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22
            nodePackages.typescript-language-server
            nodePackages.prettier
            nixfmt
            nil
          ];

          shellHook = ''
            echo "BALANCE dev environment loaded"
            echo "Node $(node --version) | npm $(npm --version)"
          '';
        };
      }
    );
}
