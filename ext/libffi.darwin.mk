# -*- makefile -*-

build_ffi = \
	mkdir -p $(BUILD_DIR)/libffi-$(1); \
	(if [ ! -f $(BUILD_DIR)/libffi-$(1)/Makefile ]; then \
	    echo "Configuring libffi for $(1)"; \
	    cd $(BUILD_DIR)/libffi-$(1) && \
	      env CFLAGS="-arch $(1) $(FFI_CFLAGS)" LDFLAGS="-arch $(1)" \
		$(FFI_CONFIGURE) --host=$(1)-apple-darwin > /dev/null; \
	fi); \
	env MACOSX_DEPLOYMENT_TARGET=10.4 $(MAKE) -C $(BUILD_DIR)/libffi-$(1)
	
$(LIBFFI):
	@$(call build_ffi,i386)
	@$(call build_ffi,ppc)
	@$(call build_ffi,x86_64)
	
	# Assemble into a FAT (i386, ppc) library
	@mkdir -p $(BUILD_DIR)/libffi/.libs
	env MACOSX_DEPLOYMENT_TARGET=10.4 /usr/bin/libtool -static -o $@ \
            $(BUILD_DIR)/libffi-i386/.libs/libffi_convenience.a \
	    $(BUILD_DIR)/libffi-x86_64/.libs/libffi_convenience.a \
	    $(BUILD_DIR)/libffi-ppc/.libs/libffi_convenience.a
	@mkdir -p $(LIBFFI_BUILD_DIR)/include
	$(RM) $(LIBFFI_BUILD_DIR)/include/ffi.h
	@( \
		printf "#if defined(__i386__)\n"; \
		printf "#include \"libffi-i386/include/ffi.h\"\n"; \
		printf "#elif defined(__x86_64__)\n"; \
		printf "#include \"libffi-x86_64/include/ffi.h\"\n";\
		printf "#elif defined(__ppc__)\n"; \
		printf "#include \"libffi-ppc/include/ffi.h\"\n";\
		printf "#endif\n";\
	) > $(LIBFFI_BUILD_DIR)/include/ffi.h
	@( \
		printf "#if defined(__i386__)\n"; \
		printf "#include \"libffi-i386/include/ffitarget.h\"\n"; \
		printf "#elif defined(__x86_64__)\n"; \
		printf "#include \"libffi-x86_64/include/ffitarget.h\"\n";\
		printf "#elif defined(__ppc__)\n"; \
		printf "#include \"libffi-ppc/include/ffitarget.h\"\n";\
		printf "#endif\n";\
	) > $(LIBFFI_BUILD_DIR)/include/ffitarget.h
	