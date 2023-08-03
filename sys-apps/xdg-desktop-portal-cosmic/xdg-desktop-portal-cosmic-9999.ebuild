# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo

DESCRIPTION="Backend implementation for xdg-desktop-portal using COSMIC"
HOMEPAGE="https://github.com/pop-os/xdg-desktop-portal-cosmic"

EGIT_REPO_URI="https://github.com/pop-os/xdg-desktop-portal-cosmic"
EGIT_COMMIT="48acd11c7379545f7d0bd1e97b1c4119b08889bc"
inherit git-r3

# License set may be more restrictive as OR is not respected
# use cargo-license for a more accurate license picture
LICENSE="GPL-3"
SLOT="0"

DEPEND="
	dev-util/just
"
RDEPEND="${DEPEND}"
BDEPEND=""

# rust does not use *FLAGS from make.conf, silence portage warning
# update with proper path to binaries this crate installs, omit leading /
QA_FLAGS_IGNORED="usr/bin/${PN}"

src_unpack() {
	git-r3_src_unpack
	cd "${WORKDIR}/${P}"
	git checkout "${EGIT_COMMIT}" || die "Failed to checkout commit ${EGIT_COMMIT}"
	cargo_live_src_unpack
}

src_install() {
	just install
}
