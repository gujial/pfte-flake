{
  description = "PFTE packaged from upstream .deb";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        pfteFontsConf = pkgs.makeFontsConf {
          fontDirectories = [
            pkgs.dejavu_fonts
            pkgs.noto-fonts
          ];
        };
      in {
        packages.default = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "pfte";
          version = "15.0.8";

          src = pkgs.fetchurl {
            url = "https://paranoiaworks.mobi/download/files/pfte_15.0.8-1_amd64.deb";
            sha256 = "MbP64w0+JoBPXtd7vWaSDoJAQqI5yUcgAj3e14xXHjw=";
          };

          nativeBuildInputs = [
            pkgs.dpkg
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];

          buildInputs = [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.expat
            pkgs.alsa-lib
            pkgs.cups
            pkgs.dbus
            pkgs.nss
            pkgs.nspr
            pkgs.glib
            pkgs.gtk3
            pkgs.pango
            pkgs.cairo
            pkgs.freetype
            pkgs.fontconfig
            pkgs.dejavu_fonts
            pkgs.noto-fonts
            pkgs.libglvnd
            pkgs.libx11
            pkgs.libxext
            pkgs.libxi
            pkgs.libxrender
            pkgs.libxtst
            pkgs.libxt
            pkgs.libxrandr
            pkgs.libxcursor
            pkgs.libxfixes
            pkgs.libxinerama
            pkgs.libxcb
          ];

          dontUnpack = true;

          installPhase = ''
            runHook preInstall

            mkdir -p "$TMPDIR/deb"
            dpkg-deb -x "$src" "$TMPDIR/deb"

            cp -a "$TMPDIR/deb"/. "$out"/

            mkdir -p "$out/bin"
            real_pfte=""

            # Try common install locations for the upstream binary.
            for candidate in \
              "$out/opt/pfte/bin/Paranoia File and Text Encryption" \
              "$out/opt/pfte/pfte" \
              "$out/opt/PFTE/pfte" \
              "$out/opt/PFTE/PFTE" \
              "$out/usr/bin/pfte"
            do
              if [ -x "$candidate" ]; then
                real_pfte="$candidate"
                break
              fi
            done

            # Fallback: locate any executable named like pfte.
            if [ -z "$real_pfte" ]; then
              candidate="$(find "$out" -type f -perm -0100 | grep -Ei '/(pfte|PFTE)$' | head -n1 || true)"
              if [ -n "$candidate" ]; then
                real_pfte="$candidate"
              fi
            fi

            if [ -z "$real_pfte" ]; then
              echo "Could not find PFTE executable in extracted deb payload" >&2
              exit 1
            fi

            makeWrapper "$real_pfte" "$out/bin/pfte" \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.expat
                pkgs.alsa-lib
                pkgs.cups
                pkgs.dbus
                pkgs.nss
                pkgs.nspr
                pkgs.glib
                pkgs.gtk3
                pkgs.pango
                pkgs.cairo
                pkgs.freetype
                pkgs.fontconfig
                pkgs.libglvnd
                pkgs.libx11
                pkgs.libxext
                pkgs.libxi
                pkgs.libxrender
                pkgs.libxtst
                pkgs.libxt
                pkgs.libxrandr
                pkgs.libxcursor
                pkgs.libxfixes
                pkgs.libxinerama
                pkgs.libxcb
              ]}" \
              --set FONTCONFIG_FILE "${pfteFontsConf}" \
              --set JAVA_FONTS "${pkgs.dejavu_fonts}/share/fonts/truetype:${pkgs.noto-fonts}/share/fonts"

            mkdir -p "$out/share/applications"
            cat > "$out/share/applications/pfte.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=PFTE
Comment=Paranoia File and Text Encryption
Exec=$out/bin/pfte
Icon=pfte
Terminal=false
Categories=Utility;Security;
StartupNotify=true
EOF

            # Reuse icon from the extracted deb when possible.
            icon_candidate="$(find "$out" -type f | grep -Ei '/(pfte|PFTE).*(\.png|\.svg|\.xpm)$' | head -n1 || true)"
            if [ -n "$icon_candidate" ]; then
              mkdir -p "$out/share/icons/hicolor/256x256/apps"
              ln -s "$icon_candidate" "$out/share/icons/hicolor/256x256/apps/pfte$(echo "$icon_candidate" | sed -E 's|.*(\.[^.]+)$|\1|')"
            fi

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Paranoia File and Text Encryption (packaged from .deb)";
            homepage = "https://paranoiaworks.mobi/encrypted-text.php";
            platforms = platforms.linux;
            sourceProvenance = [ sourceTypes.binaryNativeCode ];
            license = licenses.unfree;
            mainProgram = "pfte";
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/pfte";
        };
      });
}
