package=bls-dash
$(package)_version=1.2.0
$(package)_download_path=https://github.com/dashpay/bls-signatures/archive
$(package)_download_file=$($(package)_version).tar.gz
$(package)_file_name=$(package)-$($(package)_download_file)
$(package)_build_subdir=build
$(package)_sha256_hash=94e49f3eaa29bc1f354cd569c00f4f4314d1c8ab4758527c248b67da9686135a
$(package)_dependencies=gmp cmake

$(package)_relic_version=aecdcae7956f542fbee2392c1f0feb0a8ac41dc5
$(package)_relic_download_path=https://github.com/relic-toolkit/relic/archive
$(package)_relic_download_file=$($(package)_relic_version).tar.gz
$(package)_relic_file_name=relic-$($(package)_relic_download_file)
$(package)_relic_build_subdir=relic
$(package)_relic_sha256_hash=f2de6ebdc9def7077f56c83c8b06f4da5bacc36b709514bd550a92a149e9fa1d

$(package)_libsodium_version=1.0.18
$(package)_libsodium_download_path=https://github.com/wagerr-builder/libsodium-cmake/releases/download/V1.0.18
$(package)_libsodium_download_file=libsodium-cmake-$($(package)_libsodium_version).tar.gz
$(package)_libsodium_file_name=$($(package)_libsodium_download_file)
$(package)_libsodium_build_subdir=build/_deps/sodium-subbuild
$(package)_libsodium_sha256_hash=13b8939f75bebd6ff0fac49548fbe1a4c2ac477444b2d68a7621e233339e0874

$(package)_extra_sources = $($(package)_relic_file_name)
$(package)_extra_sources += $($(package)_libsodium_file_name)

$(package)_patches = libsodium-bls.patch

define $(package)_fetch_cmds
$(call fetch_file,$(package),$($(package)_download_path),$($(package)_download_file),$($(package)_file_name),$($(package)_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_relic_download_path),$($(package)_relic_download_file),$($(package)_relic_file_name),$($(package)_relic_sha256_hash)) && \
$(call fetch_file,$(package),$($(package)_libsodium_download_path),$($(package)_libsodium_download_file),$($(package)_libsodium_file_name),$($(package)_libsodium_sha256_hash))
endef

define $(package)_extract_cmds
  mkdir -p $($(package)_extract_dir) && \
  echo "$($(package)_sha256_hash)  $($(package)_source)" > $($(package)_extract_dir)/.$($(package)_file_name).hash && \
  echo "$($(package)_relic_sha256_hash)  $($(package)_source_dir)/$($(package)_relic_file_name)" >> $($(package)_extract_dir)/.$($(package)_file_name).hash && \
  echo "$($(package)_libsodium_sha256_hash)  $($(package)_source_dir)/$($(package)_libsodium_file_name)" >> $($(package)_extract_dir)/.$($(package)_file_name).hash && \
  $(build_SHA256SUM) -c $($(package)_extract_dir)/.$($(package)_file_name).hash && \
  tar --strip-components=1 -xf $($(package)_source) -C . && \
  cp $($(package)_source_dir)/$($(package)_relic_file_name) . && \
  cp $($(package)_source_dir)/$($(package)_libsodium_file_name) .
endef

define $(package)_set_vars
  $(package)_config_opts=-DCMAKE_INSTALL_PREFIX=$(host_prefix)
  $(package)_config_opts+= -DCMAKE_PREFIX_PATH=$(host_prefix)
  $(package)_config_opts+= -DSTLIB=ON -DSHLIB=OFF -DSTBIN=OFF
  $(package)_config_opts+= -DBUILD_BLS_PYTHON_BINDINGS=0 -DBUILD_BLS_TESTS=0 -DBUILD_BLS_BENCHMARKS=0
  $(package)_config_opts_linux=-DOPSYS=LINUX -DCMAKE_SYSTEM_NAME=Linux
  $(package)_config_opts_darwin=-DOPSYS=MACOSX -DCMAKE_SYSTEM_NAME=Darwin
  ifeq ($(strip $(FORCE_USE_SYSTEM_CLANG)),)
    $(package)_config_opts_darwin+= -DCMAKE_AR=$(host_prefix)/native/bin/$(host)-ar
    $(package)_config_opts_darwin+= -DCMAKE_RANLIB=$(host_prefix)/native/bin/$(host)-ranlib
  else
    $(package)_config_opts_darwin+= -DCMAKE_AR="$($(package)_ar)"
    $(package)_config_opts_darwin+= -DCMAKE_RANLIB="$($(package)_ranlib)"
  endif
  $(package)_config_opts_mingw32=-DOPSYS=WINDOWS -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS=""
  $(package)_config_opts_i686+= -DWSIZE=32
  $(package)_config_opts_x86_64+= -DWSIZE=64
  $(package)_config_opts_arm+= -DWSIZE=32
  $(package)_config_opts_armv7l+= -DWSIZE=32
  $(package)_config_opts_debug=-DDEBUG=ON -DCMAKE_BUILD_TYPE=Debug

  $(package)_cppflags+=-UBLSALLOC_SODIUM
endef

define $(package)_preprocess_cmds
  patch -p1 -i $($(package)_patch_dir)/libsodium-bls.patch && \
  sed -i.old "s|GIT_REPOSITORY https://github.com/Chia-Network/relic.git|URL \"../../relic-$($(package)_relic_version).tar.gz\"|" CMakeLists.txt && \
  sed -i.old "s|RELIC_GIT_TAG \".*\"|RELIC_GIT_TAG \"\"|" CMakeLists.txt
endef

define $(package)_config_cmds
  export CC="$($(package)_cc)" && \
  export CXX="$($(package)_cxx)" && \
  export CFLAGS="$($(package)_cflags) $($(package)_cppflags)" && \
  export CXXFLAGS="$($(package)_cxxflags) $($(package)_cppflags)" && \
  export LDFLAGS="$($(package)_ldflags)" && \
  $(host_prefix)/bin/cmake ../ $($(package)_config_opts)
endef

define $(package)_build_cmds
  $(MAKE) $($(package)_build_opts)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef