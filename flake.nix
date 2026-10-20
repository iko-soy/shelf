{
  description = "%shelf: a public web page listing the apps an Urbit ship publishes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The desk: copy it into a mounted %shelf desk and |commit it.
      packages = forAllSystems (pkgs: {
        default = pkgs.runCommandLocal "shelf-desk" { } ''
          cp -r ${./desk} $out
        '';
      });
    };
}
