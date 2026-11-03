{
  description = "libxmlb — Ruby bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "libxmlb-gemspec" { } ''
          mkdir -p $out/lib/libxmlb
          cp ${./libxmlb.gemspec}         $out/libxmlb.gemspec
          cp ${./lib/libxmlb/version.rb}  $out/lib/libxmlb/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "libxmlb-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

        # The namespaces the loader needs at require time: Xmlb itself, and
        # Gio/GLib/GObject which Xmlb-2.0.typelib declares as dependencies and
        # the loader resolves transitively.
        #
        # `makeSearchPath` would take each package's *first* output, and glib's
        # first output is `bin`, which carries no typelibs -- hence the explicit
        # `.out`. This is the same trap the port scaffold documents.
        # Outputs are named explicitly here, with no `drv.out or drv` map.
        #
        # That map is the right idiom when a package's typelib is in its
        # default output and the default happens to be `bin` -- glib's case.
        # It is wrong here: `pkgs.libxmlb.lib` already selects the output
        # holding `Xmlb-2.0.typelib`, and asking for `.out` on it
        # redirects to the package's default output, which has no typelibs:
        #
        #   pkgs.libxmlb.lib            -> ...-malcontent-0.13.1-lib   (correct)
        #   (pkgs.libxmlb.lib.out or ...)  -> ...-malcontent-0.13.1       (no typelib)
        #
        # which fails at require time as
        # "Typelib file for namespace 'Libxmlb' not found".
        typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0"
          [ pkgs.libxmlb.lib pkgs.glib.out ];
      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # libxmlb.lib itself, for its typelib. Taking it from the same
            # nixpkgs as the gobject-introspection gem is not a tidiness
            # point: a typelib built against a different glib registers GIO a
            # second time in the process and dies with
            #   cannot register existing type 'GTlsCertificate'
            libxmlb.lib

            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            # Xmlb-2.0.typelib and the typelibs it declares, which the loader
            # resolves transitively at require time. A missing one surfaces as
            # "Typelib file for namespace 'X' not found", one at a time.
            export GI_TYPELIB_PATH="${typelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
          '';
        };
      }
    );
}
