TARGET = pazi.out
CXX = g++
CXXFLAGS = -Ofast -march=native -fopenmp

M4_ARCHIVE = m4-1.4.19.tar.gz
M4_SRC_DIR = m4-1.4.19
M4_INSTALL = $(PWD)/m4-install

GMP_ARCHIVE = gmp-6.2.1.tar.xz
GMP_SRC_DIR = gmp-6.2.1

ifneq ($(shell command -v m4 >/dev/null 2>&1 && echo 1),1)
  M4_CMD = $(M4_INSTALL)/bin/m4
else
  M4_CMD = m4
endif

.PHONY: all clean check_m4 build_m4 check_gmp build_gmp

all: check_m4 check_gmp $(TARGET)
	echo
	echo "=== Запускаем ./$(TARGET) ==="
	@LD_LIBRARY_PATH=$(GMP_SRC_DIR)/.libs:$$LD_LIBRARY_PATH ./$(TARGET)

check_m4:
	@if command -v m4 >/dev/null 2>&1; then \
		echo "Found system m4, skipping build..."; \
	else \
		echo "No system m4 found, building local m4..."; \
		$(MAKE) build_m4; \
	fi

build_m4: $(M4_SRC_DIR)/m4

$(M4_SRC_DIR):
	tar -xzf $(M4_ARCHIVE)

$(M4_SRC_DIR)/config.status: | $(M4_SRC_DIR)
	cd $(M4_SRC_DIR) && ./configure --prefix=$(M4_INSTALL)

$(M4_SRC_DIR)/m4: $(M4_SRC_DIR)/config.status
	make -C $(M4_SRC_DIR)
	make -C $(M4_SRC_DIR) install

check_gmp:
	@if echo "#include <gmpxx.h>\nint main(){}" \
	| $(CXX) -xc++ - -lgmpxx -lgmp -o /dev/null 2>/dev/null; then \
		echo "Found system GMP, skipping build..."; \
	else \
		echo "No system GMP found, building local GMP..."; \
		$(MAKE) build_gmp; \
	fi

build_gmp: $(GMP_SRC_DIR)/libgmpxx.la

$(GMP_SRC_DIR):
	tar -xf $(GMP_ARCHIVE)

$(GMP_SRC_DIR)/config.status: | $(GMP_SRC_DIR)
	cd $(GMP_SRC_DIR) && M4=$(M4_CMD) ./configure --enable-cxx

$(GMP_SRC_DIR)/libgmpxx.la: $(GMP_SRC_DIR)/config.status
	make -C $(GMP_SRC_DIR)

$(TARGET): $(GMP_SRC_DIR)/libgmpxx.la pazi.cpp
	@$(CXX) $(CXXFLAGS) pazi.cpp \
		-I $(GMP_SRC_DIR) \
		-L $(GMP_SRC_DIR)/.libs \
		-lgmpxx -lgmp \
		-o $(TARGET) \
		-Wl,-rpath,$(GMP_SRC_DIR)/.libs

clean:
	@$(MAKE) -C $(GMP_SRC_DIR) clean || true
	@$(MAKE) -C $(M4_SRC_DIR) clean || true
	@rm -f $(TARGET)
