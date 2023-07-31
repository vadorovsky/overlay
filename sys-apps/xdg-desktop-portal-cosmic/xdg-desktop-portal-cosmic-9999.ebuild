# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	adler-1.0.2
	aho-corasick-1.0.1
	anyhow-1.0.71
	async-broadcast-0.5.1
	async-channel-1.8.0
	async-executor-1.5.1
	async-fs-1.6.0
	async-global-executor-2.3.1
	async-io-1.13.0
	async-lock-2.7.0
	async-process-1.7.0
	async-recursion-1.0.4
	async-std-1.12.0
	async-task-4.4.0
	async-trait-0.1.68
	atomic-waker-1.1.1
	autocfg-1.1.0
	bindgen-0.64.0
	bitflags-1.3.2
	bitflags-2.2.1
	block-buffer-0.10.4
	blocking-1.3.1
	bumpalo-3.12.2
	byteorder-1.4.3
	bytes-1.4.0
	calloop-0.10.5
	cc-1.0.79
	cexpr-0.6.0
	cfg-expr-0.15.1
	cfg-if-1.0.0
	clang-sys-1.6.1
	concurrent-queue-2.2.0
	cookie-factory-0.3.2
	cpufeatures-0.2.7
	crc32fast-1.3.2
	crossbeam-utils-0.8.15
	crypto-common-0.1.6
	ctor-0.1.26
	derivative-2.2.0
	digest-0.10.6
	dlib-0.5.0
	downcast-rs-1.2.0
	enumflags2-0.7.7
	enumflags2_derive-0.7.7
	errno-0.3.1
	errno-dragonfly-0.1.2
	event-listener-2.5.3
	fastrand-1.9.0
	fdeflate-0.3.0
	flate2-1.0.26
	form_urlencoded-1.1.0
	futures-0.3.28
	futures-channel-0.3.28
	futures-core-0.3.28
	futures-executor-0.3.28
	futures-io-0.3.28
	futures-lite-1.13.0
	futures-macro-0.3.28
	futures-sink-0.3.28
	futures-task-0.3.28
	futures-util-0.3.28
	generic-array-0.14.7
	getrandom-0.2.9
	glob-0.3.1
	gloo-timers-0.2.6
	hashbrown-0.12.3
	heck-0.4.1
	hermit-abi-0.3.1
	hex-0.4.3
	idna-0.3.0
	indexmap-1.9.3
	instant-0.1.12
	io-lifetimes-1.0.10
	js-sys-0.3.62
	kv-log-macro-1.0.7
	lazy_static-1.4.0
	lazycell-1.3.0
	libc-0.2.144
	libloading-0.7.4
	linux-raw-sys-0.3.7
	log-0.4.17
	memchr-2.5.0
	memmap2-0.5.10
	memmap2-0.6.1
	memoffset-0.6.5
	memoffset-0.7.1
	minimal-lexical-0.2.1
	miniz_oxide-0.7.1
	mio-0.8.6
	nix-0.25.1
	nix-0.26.2
	nom-7.1.3
	once_cell-1.17.1
	ordered-stream-0.2.0
	parking-2.1.0
	peeking_take_while-0.1.2
	percent-encoding-2.2.0
	pin-project-lite-0.2.9
	pin-utils-0.1.0
	pkg-config-0.3.27
	png-0.17.8
	polling-2.8.0
	ppv-lite86-0.2.17
	proc-macro-crate-1.3.1
	proc-macro2-1.0.56
	quick-xml-0.23.1
	quote-1.0.27
	rand-0.8.5
	rand_chacha-0.3.1
	rand_core-0.6.4
	redox_syscall-0.3.5
	regex-1.8.1
	regex-syntax-0.7.1
	rustc-hash-1.1.0
	rustix-0.37.19
	scoped-tls-1.0.1
	serde-1.0.163
	serde_derive-1.0.163
	serde_repr-0.1.12
	serde_spanned-0.6.1
	sha1-0.10.5
	shlex-1.1.0
	signal-hook-0.3.15
	signal-hook-registry-1.4.1
	simd-adler32-0.3.5
	slab-0.4.8
	slotmap-1.0.6
	smallvec-1.10.0
	socket2-0.4.9
	static_assertions-1.1.0
	syn-1.0.109
	syn-2.0.15
	system-deps-6.1.0
	target-lexicon-0.12.7
	tempfile-3.5.0
	thiserror-1.0.40
	thiserror-impl-1.0.40
	tinyvec-1.6.0
	tinyvec_macros-0.1.1
	tokio-1.28.1
	tokio-macros-2.1.0
	toml-0.7.3
	toml_datetime-0.6.1
	toml_edit-0.19.8
	tracing-0.1.37
	tracing-attributes-0.1.24
	tracing-core-0.1.31
	typenum-1.16.0
	uds_windows-1.0.2
	unicode-bidi-0.3.13
	unicode-ident-1.0.8
	unicode-normalization-0.1.22
	url-2.3.1
	value-bag-1.0.0-alpha.9
	vec_map-0.8.2
	version-compare-0.1.1
	version_check-0.9.4
	waker-fn-1.1.0
	wasi-0.11.0+wasi-snapshot-preview1
	wasm-bindgen-0.2.85
	wasm-bindgen-backend-0.2.85
	wasm-bindgen-futures-0.4.35
	wasm-bindgen-macro-0.2.85
	wasm-bindgen-macro-support-0.2.85
	wasm-bindgen-shared-0.2.85
	wayland-backend-0.1.2
	wayland-client-0.30.1
	wayland-cursor-0.30.0
	wayland-protocols-0.30.0
	wayland-protocols-wlr-0.1.0
	wayland-scanner-0.30.0
	wayland-server-0.30.0
	wayland-sys-0.30.1
	web-sys-0.3.62
	winapi-0.3.9
	winapi-i686-pc-windows-gnu-0.4.0
	winapi-x86_64-pc-windows-gnu-0.4.0
	windows-sys-0.45.0
	windows-sys-0.48.0
	windows-targets-0.42.2
	windows-targets-0.48.0
	windows_aarch64_gnullvm-0.42.2
	windows_aarch64_gnullvm-0.48.0
	windows_aarch64_msvc-0.42.2
	windows_aarch64_msvc-0.48.0
	windows_i686_gnu-0.42.2
	windows_i686_gnu-0.48.0
	windows_i686_msvc-0.42.2
	windows_i686_msvc-0.48.0
	windows_x86_64_gnu-0.42.2
	windows_x86_64_gnu-0.48.0
	windows_x86_64_gnullvm-0.42.2
	windows_x86_64_gnullvm-0.48.0
	windows_x86_64_msvc-0.42.2
	windows_x86_64_msvc-0.48.0
	winnow-0.4.1
	xcursor-0.3.4
	xdg-home-1.0.0
	xkbcommon-0.5.0
	zbus-3.13.0
	zbus_macros-3.13.0
	zbus_names-2.5.1
	zvariant-3.13.0
	zvariant_derive-3.13.0
	zvariant_utils-1.0.0
"

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
