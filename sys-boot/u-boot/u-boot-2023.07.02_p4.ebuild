# Copyright 2023 James Calligeros <jcalligeros99@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
PYTHON_COMPAT=( python3_{10..11} )

inherit toolchain-funcs

DESCRIPTION="Asahi Linux fork of Das U-Boot"
HOMEPAGE="https://asahilinux.org/"
LICENSE="GPL-2"
KEYWORDS="arm64"
SLOT="0"

# $PV is expected to be of following form: 2023.07.02_p2
MY_TAG="$(ver_cut 5)"
MY_P="asahi-v$(ver_cut 1-3)-${MY_TAG}"

SRC_URI="https://github.com/AsahiLinux/u-boot/archive/refs/tags/${MY_P}.tar.gz -> ${PN}-${PV}.tar.gz"

BDEPEND="
	app-arch/cpio
	dev-lang/perl
	sys-devel/bc
	sys-devel/bison
	sys-devel/flex
	sys-devel/make
	>=sys-libs/ncurses-5.2
	virtual/libelf
	virtual/pkgconfig
	sys-apps/dtc
	dev-vcs/git"

RDEPEND="${BDEPEND}
	sys-apps/asahi-scripts"

PATCHES=(
	"${FILESDIR}/u-boot-2023.07.02_p4-arm64-Remove-duplicated-symbols.patch"
	"${FILESDIR}/u-boot-2023.07.02_p4-arm-efi_loader-move-.dynamic-out-of-.text-in-EFI.patch"
	"${FILESDIR}/u-boot-2023.07.02_p4-pci-apple-Initialize-and-increment-the-port-counter.patch"
)

src_unpack() {
	unpack ${PN}-${PV}.tar.gz || die "Could not unpack sources!"
	mv u-boot-${MY_P} ${PN}-${PV}
}

src_configure() {
	local makeargs=(
		CC="$(tc-getBUILD_CC)"
		CXX="$(tc-getBUILD_CXX)"
		HOSTCC="$(tc-getBUILD_CC)"
		HOSTCXX="$(tc-getBUILD_CXX)"
		HOSTCFLAGS="${BUILD_CFLAGS}"
		HOSTLDFLAGS="${BUILD_LDFLAGS}"
	)
	emake "${makeargs[@]}" apple_m1_defconfig || die "failed to apply defconfig!"
}

src_compile() {
	cd "${S}" || die
	local makeargs=(
		CC="$(tc-getBUILD_CC)"
		CXX="$(tc-getBUILD_CXX)"
		HOSTCC="$(tc-getBUILD_CC)"
		HOSTCXX="$(tc-getBUILD_CXX)"
		HOSTCFLAGS="${BUILD_CFLAGS}"
		HOSTLDFLAGS="${BUILD_LDFLAGS}"
	)
	emake "${makeargs[@]}" || die "emake failed"
}

src_install() {
	dodir /usr/lib/asahi-boot
	cp "${S}"/u-boot-nodtb.bin "${ED}"/usr/lib/asahi-boot/u-boot-nodtb.bin || die
}

pkg_postinst() {
	elog "U-Boot has been installed to /usr/lib/asahi-boot/u-boot-nodtb.bin."
	elog "You must run update-m1n1 for the new version to be installed"
	elog "in the ESP."
	elog "Please see the Asahi Linux Wiki for more information."
}

pkg_postrm() {
	elog "U-Boot has been removed from /usr/lib/asahi-boot/ but has not"
	elog "been removed from the ESP. You need to do this manually, though"
	elog "you really shouldn't."
}
