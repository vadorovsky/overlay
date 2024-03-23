# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake crossdev flag-o-matic llvm llvm.org toolchain-funcs

DESCRIPTION="Compiler runtime library for GCC (LLVM compatible version)"
HOMEPAGE="https://llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="0"
KEYWORDS="amd64 arm arm64 ppc64 ~riscv x86 ~amd64-linux"
IUSE="+abi_x86_32 abi_x86_64 debug"

DEPEND="
	sys-devel/llvm:${LLVM_MAJOR}
	=sys-libs/compiler-rt-${LLVM_VERSION}*
	=sys-libs/llvm-libunwind-${LLVM_VERSION}*[static-libs]
	!!sys-devel/gcc
"
BDEPEND="
	>=dev-build/cmake-3.16
"

LLVM_COMPONENTS=( compiler-rt cmake llvm/cmake llvm-libgcc )
llvm.org_set_globals

pkg_setup() {
	if target_is_not_host || tc-is-cross-compiler ; then
		# strips vars like CFLAGS="-march=x86_64-v3" for non-x86 architectures
		CHOST=${CTARGET} strip-unsupported-flags
		# overrides host docs otherwise
		DOCS=()
	fi
}

src_configure() {
	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"

	# pre-set since we need to pass it to cmake
	BUILD_DIR=${WORKDIR}/${P}_build

	# NOTE(vadorovsky): This check is failing when cross-compiling.
	# if ! tc-is-clang ; then
	# 	die "this package is for clang only system"
	# fi

	strip-unsupported-flags

	local mycmakeargs=(
		-DCOMPILER_RT_INSTALL_PATH="${EPREFIX}/usr/lib/"

		-DCOMPILER_RT_INCLUDE_TESTS=OFF
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF
		-DCOMPILER_RT_BUILD_MEMPROF=OFF
		-DCOMPILER_RT_BUILD_ORC=OFF
		-DCOMPILER_RT_BUILD_PROFILE=OFF
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF
		-DCOMPILER_RT_BUILD_XRAY=OFF
		-DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF
	)

	if use amd64; then
		mycmakeargs+=(
			-DCAN_TARGET_i386=$(usex abi_x86_32)
			-DCAN_TARGET_x86_64=$(usex abi_x86_64)
		)
	fi

	if target_is_not_host || tc-is-cross-compiler ; then
		# Needed to target built libc headers
		export CFLAGS="${CFLAGS} -isystem /usr/${CTARGET}/usr/include"
		mycmakeargs+=(
			# Without this, the compiler will compile a test program
			# and fail due to no builtins.
			-DCMAKE_C_COMPILER_WORKS=1
			-DCMAKE_CXX_COMPILER_WORKS=1

			# Without this, compiler-rt install location is not unique
			# to target triples, only to architecture.
			# Needed if you want to target multiple libcs for one arch.
			-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON

			-DCMAKE_ASM_COMPILER_TARGET="${CTARGET}"
			-DCMAKE_C_COMPILER_TARGET="${CTARGET}"
			-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
		)
	fi

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	# For host builds, compiler-rt builtins are in ${BUILD_DIR}/lib/linux directory.
	# For cross builds, a target triple is used instead of "linux", so they are in
	# ${BUILD_DIR}/lib/${CTARGET} (e.g. ${BUILD_DIR}/lib/aarch64-gentoo-linux-musl).
	RT_BUILTINS_DIR="linux"
	if target_is_not_host || tc-is-cross-compiler ; then
		RT_BUILTINS_DIR="${CTARGET}"
	fi

	shopt -s nullglob
	$(tc-getCC) --target=${CTARGET} --sysroot=${ESYSROOT} \
		-E -xc ${WORKDIR}/llvm-libgcc/gcc_s.ver.in -o ${BUILD_DIR}/gcc_s.ver || die
	$(tc-getCC) --target=${CTARGET} --sysroot=${ESYSROOT} ${LDFLAGS} -nostdlib \
		-Wl,-znodelete,-zdefs -Wl,--version-script,${BUILD_DIR}/gcc_s.ver \
		-Wl,--whole-archive ${ESYSROOT}/usr/lib/libunwind.a ${BUILD_DIR}/lib/${RT_BUILTINS_DIR}/libclang_rt.builtins*.a \
		-Wl,-soname,libgcc_s.so.1.0 -lc -shared -o ${BUILD_DIR}/libgcc_s.so.1.0
	shopt -u nullglob
}

src_install() {
	# For host builds, compiler-rt builtins are in ${BUILD_DIR}/lib/linux directory.
	# For cross builds, a target triple is used instead of "linux", so they are in
	# ${BUILD_DIR}/lib/${CTARGET} (e.g. ${BUILD_DIR}/lib/aarch64-gentoo-linux-musl).
	RT_BUILTINS_DIR="linux"
	if target_is_not_host || tc-is-cross-compiler ; then
		RT_BUILTINS_DIR="${CTARGET}"
	fi

	shopt -s nullglob
	dolib.so ${BUILD_DIR}/libgcc_s.so.1.0
	newlib.a ${BUILD_DIR}/lib/${RT_BUILTINS_DIR}/libclang_rt.builtins*.a libgcc.a
	dosym libgcc_s.so.1.0 /usr/lib/libgcc_s.so.1
	dosym libgcc_s.so.1 /usr/lib/libgcc_s.so
	dosym libunwind.a /usr/lib/libgcc_eh.a
	shopt -u nullglob
}
