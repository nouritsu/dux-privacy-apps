{
  lib,
  stdenvNoCC,
  writeShellApplication,
  coreutils,
}: let
  # a stream's pid -> its app's main process (oldest ancestor on the same
  # binary, so a browser's audio helper resolves to the browser) and binary
  owner = writeShellApplication {
    name = "dux-privacy-apps-owner";
    runtimeInputs = [coreutils];
    text = ''
      exe=$(readlink "/proc/$1/exe")
      top=$1
      while :; do
        ppid=0
        while read -r key value; do
          if [ "$key" = PPid: ]; then
            ppid=$value
            break
          fi
        done < "/proc/$top/status"
        if [ "$ppid" -le 1 ] || [ "$(readlink "/proc/$ppid/exe")" != "$exe" ]; then
          break
        fi
        top=$ppid
      done
      echo "$top ''${exe##*/}"
    '';
  };
in
  stdenvNoCC.mkDerivation {
    pname = "dux-privacy-apps";
    inherit (lib.importJSON ../plugin/plugin.json) version;

    src = ../plugin;

    installPhase = ''
      runHook preInstall
      cp -r . $out
      substituteInPlace $out/PrivacyAppsDaemon.qml \
        --replace-fail @owner@ ${lib.getExe owner}
      runHook postInstall
    '';
  }
