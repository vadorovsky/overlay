# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake crossdev flag-o-matic llvm llvm.org toolchain-funcs

DESCRIPTION="Compiler runtime library for GCC (LLVM compatible version)"
HOMEPAGE="https://llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86 ~amd64-linux"
IUSE="+abi_x86_32 abi_x86_64 debug"

DEPEND="
	sys-devel/llvm:${LLVM_MAJOR}
	=sys-libs/compiler-rt-${LLVM_VERSION}*
	=sys-libs/llvm-libunwind-${LLVM_VERSION}*[static-libs]
	!!sys-devel/gcc
"
BDEPEND="
	>=dev-build/cmake-3.16
	dev-util/patchelf
"

LLVM_COMPONENTS=( runtimes llvm-libgcc compiler-rt cmake libunwind libcxx llvm/cmake )
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

	strip-unsupported-flags

	local mycmakeargs=(
		-DCOMPILER_RT_INSTALL_PATH="${EPREFIX}/usr/lib/clang/${LLVM_MAJOR}"

		-DCOMPILER_RT_INCLUDE_TESTS=OFF
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF
		-DCOMPILER_RT_BUILD_MEMPROF=OFF
		-DCOMPILER_RT_BUILD_ORC=OFF
		-DCOMPILER_RT_BUILD_PROFILE=OFF
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF
		-DCOMPILER_RT_BUILD_XRAY=OFF
		-DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF
		# It breaks on musl with "undefined symbol: __getauxval" error.
		-DCOMPILER_RT_HAS_AARCH64_SME=OFF

		-DLIBUNWIND_ENABLE_CROSS_UNWINDING=ON

		-DLLVM_ENABLE_RUNTIMES="llvm-libgcc"
		-DLLVM_INCLUDE_TESTS=OFF
		-DLLVM_LIBGCC_EXPLICIT_OPT_IN=ON
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

			-DCMAKE_ASM_COMPILER_TARGET="${CTARGET}"
			-DCMAKE_C_COMPILER_TARGET="${CTARGET}"
			-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
		)
	fi

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	patchelf --set-soname libgcc_s.so.1 ${BUILD_DIR}/lib/libunwind.so.1.0
}

src_install() {
	# The way how llvm-libgcc upstream envisions the installation is:
	#
	# - Installation of libclang_rt.builtins*.a and libunwind.{a,so} files
	#   produced by the llvm-libgcc build. These libraries contain the GNU
	#   symbols and are **not** the same as they would be if you build them
	#   without llvm-libgcc enabled.
	# - Creating symlinks:
	#   - libgcc.a -> libclang_rt.builtins*.a
	#   - libgcc_eh.a -> libunwind.a
	#   - libgcc_s.so -> libunwind.so
	#
	# However, in our case we don't want to replace the compiler-rt and libunwind
	# libraries coming from the main Gentoo ebuilds. We just want to keep the
	# libgcc_s replacement libraries alongside. Therefore, instead of making
	# symlinks, we install these libraries directly with the GNU-compatible names.

	shopt -s nullglob
	newlib.a ${BUILD_DIR}/compiler-rt/lib/linux/libclang_rt.builtins*.a libgcc.a
	newlib.a ${BUILD_DIR}/lib/libunwind.a libgcc_eh.a
	newlib.so ${BUILD_DIR}/lib/libunwind.so.1.0 libgcc_s.so.1.0
	dosym libgcc_s.so.1.0 /usr/lib/libgcc_s.so.1
	dosym libgcc_s.so.1 /usr/lib/libgcc_s.so
	shopt -u nullglob
}
