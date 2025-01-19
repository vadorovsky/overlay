# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
inherit cmake crossdev llvm.org llvm-utils python-any-r1 toolchain-funcs

DESCRIPTION="Compiler runtime library for clang, compatible with libgcc_s"
HOMEPAGE="https://llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="0"
IUSE="+abi_x86_32 abi_x86_64 +atomic-builtins debug test"

DEPEND="
	~llvm-runtimes/libunwind-${PV}[static-libs]
	!!sys-devel/gcc
"
BDEPEND="
	llvm-core/clang:${LLVM_MAJOR}
	test? (
		$(python_gen_any_dep ">=dev-python/lit-15[\${PYTHON_USEDEP}]")
		=llvm-core/clang-${LLVM_VERSION}*:${LLVM_MAJOR}
	)
	!test? (
		${PYTHON_DEPS}
	)
"

LLVM_COMPONENTS=( compiler-rt cmake llvm/cmake llvm-libgcc )
LLVM_TEST_COMPONENTS=( llvm/include/llvm/TargetParser )
llvm.org_set_globals

python_check_deps() {
	use test || return 0
	python_has_version ">=dev-python/lit-15[${PYTHON_USEDEP}]"
}

pkg_setup() {
	if target_is_not_host || tc-is-cross-compiler ; then
		# strips vars like CFLAGS="-march=x86_64-v3" for non-x86 architectures
		CHOST=${CTARGET} strip-unsupported-flags
		# overrides host docs otherwise
		DOCS=()
	fi
	python-any-r1_pkg_setup
}

src_configure() {
	llvm_prepend_path "${LLVM_MAJOR}"

	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"

	# pre-set since we need to pass it to cmake
	BUILD_DIR=${WORKDIR}/${P}_build

	local -x CC=${CTARGET}-clang CXX=${CTARGET}-clang++
	strip-unsupported-flags

	local mycmakeargs=(
		-DCOMPILER_RT_INSTALL_PATH="${EPREFIX}/usr/lib/clang/${LLVM_MAJOR}"

		-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=$(usex !atomic-builtins)
		-DCOMPILER_RT_INCLUDE_TESTS=$(usex test)
		-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF
		-DCOMPILER_RT_BUILD_MEMPROF=OFF
		-DCOMPILER_RT_BUILD_ORC=OFF
		-DCOMPILER_RT_BUILD_PROFILE=OFF
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF
		-DCOMPILER_RT_BUILD_XRAY=OFF

		-DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF

		-DPython3_EXECUTABLE="${PYTHON}"
	)

	if use amd64 && ! target_is_not_host; then
		mycmakeargs+=(
			-DCAN_TARGET_i386=$(usex abi_x86_32)
			-DCAN_TARGET_x86_64=$(usex abi_x86_64)
		)
	fi

	if use test; then
		mycmakeargs+=(
			-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
			-DLLVM_LIT_ARGS="$(get_lit_flags)"

			-DCOMPILER_RT_TEST_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/bin/clang"
			-DCOMPILER_RT_TEST_CXX_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/bin/clang++"
		)
	fi

	cmake_src_configure
}

src_compile() {
	local -x CC=${CTARGET}-clang CXX=${CTARGET}-clang++
	local libdir=$(get_libdir)

	cmake_src_compile

	$(tc-getCPP) \
		"${WORKDIR}/llvm-libgcc/gcc_s.ver.in" \
		-o gcc_s.ver || die
	$(tc-getCC) -nostdlib \
		${LDFLAGS} \
		-Wl,--version-script,gcc_s.ver \
		-Wl,--undefined-version \
		-Wl,--whole-archive \
		"${BUILD_DIR}/lib/linux/libclang_rt.builtins-${CTARGET%%-*}.a" \
		-Wl,-soname,libgcc_s.so.1.0 \
		-lc -lunwind -shared \
		-o libgcc_s.so.1.0 || die
}

src_test() {
	# respect TMPDIR!
	local -x LIT_PRESERVES_TMP=1

	cmake_build check-builtins
}

src_install() {
	local libdir=$(get_libdir)
	dolib.so libgcc_s.so.1.0
	insinto "/usr/${libdir}"
	newlib.a "${BUILD_DIR}/lib/linux/libclang_rt.builtins-${CTARGET%%-*}.a" libgcc.a
	dosym libgcc_s.so.1.0 "/usr/${libdir}/libgcc_s.so.1"
	dosym libgcc_s.so.1 "/usr/${libdir}/libgcc_s.so"
	dosym libunwind.a "/usr/${libdir}/libgcc_eh.a"
}
