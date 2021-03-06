{ config, stdenv, fetchFromGitHub, autoreconfHook, pkgconfig, help2man, fuse
, utillinux, makeWrapper
, enableDebugBuild ? config.lxcfs.enableDebugBuild or false }:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "lxcfs-4.0.3";

  src = fetchFromGitHub {
    owner = "lxc";
    repo = "lxcfs";
    rev = name;
    sha256 = "0v6c5vc3i1l4sy4iamzdqvwibj6xr1lna4w1hxkn3s6jggcbxwca";
  };

  nativeBuildInputs = [ pkgconfig help2man autoreconfHook ];
  buildInputs = [ fuse makeWrapper ];

  preConfigure = stdenv.lib.optionalString enableDebugBuild ''
    sed -i 's,#AM_CFLAGS += -DDEBUG,AM_CFLAGS += -DDEBUG,' Makefile.am
  '';

  configureFlags = [
    "--with-init-script=systemd"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  installFlags = [ "SYSTEMD_UNIT_DIR=\${out}/lib/systemd" ];

  postInstall = ''
    # `mount` hook requires access to the `mount` command from `utillinux`:
    wrapProgram "$out/share/lxcfs/lxc.mount.hook" \
      --prefix PATH : "${utillinux}/bin"
  '';

  postFixup = ''
    # liblxcfs.so is reloaded with dlopen()
    patchelf --set-rpath "$(patchelf --print-rpath "$out/bin/lxcfs"):$out/lib" "$out/bin/lxcfs"
  '';

  meta = {
    homepage = "https://linuxcontainers.org/lxcfs";
    description = "FUSE filesystem for LXC";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ mic92 fpletz ];
  };
}
