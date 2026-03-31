# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1

DESCRIPTION="Reference implementation for Bech32 and segwit addresses"
HOMEPAGE="
	https://github.com/fiatjaf/bech32
	https://pypi.org/project/bech32/
"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/fiatjaf/bech32.git"
else
	inherit pypi
	KEYWORDS="~amd64 ~arm64"
fi


LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
