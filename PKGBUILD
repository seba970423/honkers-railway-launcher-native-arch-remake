pkgname=honkers-railway-launcher-native-arch
pkgver=1.15.2
pkgrel=12
_sdkver=1.35.12
_patchrev=12
pkgdesc='Honkers Railway Launcher with native Arch enhancements'
arch=('x86_64')
url='https://github.com/an-anime-team/the-honkers-railway-launcher'
license=('GPL-3.0-only')
provides=('the-honkers-railway-launcher')
conflicts=('the-honkers-railway-launcher' 'the-honkers-railway-launcher-bin')
depends=('gtk4' 'libadwaita' 'glibc' 'hicolor-icon-theme' 'glib2'
         'gdk-pixbuf2' 'pango' 'xz' 'bzip2' 'cairo' 'p7zip' 'wayland'
         'git' 'libwebp-utils' 'winetricks' 'systemd')
makedepends=('cargo' 'patch')
optdepends=('gamemode: temporary game-oriented system optimizations'
            'system76-scheduler: foreground process scheduling over D-Bus'
            'mangohud: performance overlay, including mangoapp for Gamescope'
            'gamescope: gaming micro-compositor')
source=(
  "launcher-${pkgver}.tar.gz::https://github.com/an-anime-team/the-honkers-railway-launcher/archive/refs/tags/${pkgver}.tar.gz"
  "anime-launcher-sdk-${_sdkver}.tar.gz::https://github.com/an-anime-team/anime-launcher-sdk/archive/refs/tags/${_sdkver}.tar.gz"
  '0001-sdk-arch-enhancements.patch'
  '0002-launcher-arch-enhancements.patch'
  'verify-source.sh'
  'install-optional-dependency'
  'moe.launcher.honkers.install-optional-dependency.policy'
)
sha256sums=(
  '8bca00ada1224a3e00787c6b88d9cc4b7cce52a51e2a3c9c0bd5eae6101ba86b'
  '38526aefa1b0b75f82c52dcf9b6d8f7d5713357c04399114d744e098275dbfe6'
  '037de79103c74b3db7e555a4412dcba8e10f64773bd545f96f2ab22d7e2f879d'
  'ade52dd8d51d8b5cf67de3b003ed998c645b38bc812eb284c94d2bbc71c1cc47'
  'cc1c16047ae0dfc4108d48bc031265bf4fa98add7561fe1188aec872ced5379d'
  'c6530148229e63cae82ef1adfe2d4a1547f49ec635385df26394d935de5e7580'
  '8ad3b8e8d305c7698dff09d7430de339f74cabb4cea887d0e3056557b6421cea'
)

prepare() {
  cd "$srcdir/anime-launcher-sdk-${_sdkver}"
  patch --batch --forward --fuzz=0 -Np1 < "$srcdir/0001-sdk-arch-enhancements.patch"

  cd "$srcdir/the-honkers-railway-launcher-${pkgver}"
  patch --batch --forward --fuzz=0 -Np1 < "$srcdir/0002-launcher-arch-enhancements.patch"

  ln -sfn "anime-launcher-sdk-${_sdkver}" "$srcdir/anime-launcher-sdk"
  "$srcdir/verify-source.sh" \
    "$srcdir/the-honkers-railway-launcher-${pkgver}" \
    "$srcdir/anime-launcher-sdk-${_sdkver}"

  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
  cd "$srcdir/the-honkers-railway-launcher-${pkgver}"
  export RUSTUP_TOOLCHAIN=stable
  export CARGO_TARGET_DIR=target
  export CFLAGS+=" -ffat-lto-objects"
  cargo build --frozen --release --all-features
}

package() {
  cd "$srcdir/the-honkers-railway-launcher-${pkgver}"
  install -Dm755 target/release/honkers-railway-launcher \
    "$pkgdir/usr/bin/honkers-railway-launcher"
  install -Dm644 assets/honkers-railway-launcher.desktop \
    "$pkgdir/usr/share/applications/honkers-railway-launcher.desktop"
  install -Dm644 assets/images/icon.png \
    "$pkgdir/usr/share/icons/hicolor/512x512/apps/moe.launcher.the-honkers-railway-launcher.png"
  install -Dm644 assets/moe.launcher.the-honkers-railway-launcher.metainfo.xml \
    "$pkgdir/usr/share/metainfo/moe.launcher.the-honkers-railway-launcher.metainfo.xml"

  install -Dm755 "$srcdir/install-optional-dependency" \
    "$pkgdir/usr/lib/honkers-railway-launcher/install-optional-dependency"
  install -Dm644 "$srcdir/moe.launcher.honkers.install-optional-dependency.policy" \
    "$pkgdir/usr/share/polkit-1/actions/moe.launcher.honkers.install-optional-dependency.policy"

  sed -i 's|Exec=AppRun|Exec=honkers-railway-launcher|' \
    "$pkgdir/usr/share/applications/honkers-railway-launcher.desktop"
  sed -i 's|Icon=icon|Icon=moe.launcher.the-honkers-railway-launcher|' \
    "$pkgdir/usr/share/applications/honkers-railway-launcher.desktop"
  printf '%s\n' 'StartupWMClass=moe.launcher.the-honkers-railway-launcher' >> \
    "$pkgdir/usr/share/applications/honkers-railway-launcher.desktop"
}
