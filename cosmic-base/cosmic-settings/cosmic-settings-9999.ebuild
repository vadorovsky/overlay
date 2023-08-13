# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo

DESCRIPTION="COSMIC settings"
HOMEPAGE="https://github.com/pop-os/cosmic-settings"

EGIT_REPO_URI="https://github.com/pop-os/cosmic-settings"
EGIT_COMMIT="2d2cac5f877be849d53e01cb5541bd5fd27927a1"
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
