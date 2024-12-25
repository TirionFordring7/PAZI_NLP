TARGET = pazi.out
CXX = g++
CXXFLAGS = -Ofast -march=native -fopenmp
M4_ARCHIVE = m4-1.4.19.tar.gz
M4_SRC_DIR = m4-1.4.19
M4_INSTALL = $(PWD)/m4-install
GMP_ARCHIVE = gmp-6.2.1.tar.xz
GMP_SRC_DIR = gmp-6.2.1

.PHONY: all clean

all: $(TARGET)
	@echo
	@echo "=== Запускаем ./$(TARGET) ==="
	LD_LIBRARY_PATH=$(GMP_SRC_DIR)/.libs:$$LD_LIBRARY_PATH ./$(TARGET)

$(M4_SRC_DIR):
	tar -xzf $(M4_ARCHIVE)

$(M4_SRC_DIR)/config.status: | $(M4_SRC_DIR)
	cd $(M4_SRC_DIR) && ./configure --prefix=$(M4_INSTALL)

$(M4_SRC_DIR)/m4: $(M4_SRC_DIR)/config.status
	$(MAKE) -C $(M4_SRC_DIR)
	$(MAKE) -C $(M4_SRC_DIR) install

$(GMP_SRC_DIR):
	tar -xf $(GMP_ARCHIVE)

$(GMP_SRC_DIR)/config.status: | $(GMP_SRC_DIR) $(M4_SRC_DIR)/m4
	cd $(GMP_SRC_DIR) && M4=$(M4_INSTALL)/bin/m4 ./configure --enable-cxx

$(GMP_SRC_DIR)/libgmpxx.la: $(GMP_SRC_DIR)/config.status
	$(MAKE) -C $(GMP_SRC_DIR)

$(TARGET): $(GMP_SRC_DIR)/libgmpxx.la pazi.cpp
	$(CXX) $(CXXFLAGS) pazi.cpp -I $(GMP_SRC_DIR) -L $(GMP_SRC_DIR)/.libs -lgmpxx -lgmp -o $(TARGET) -Wl,-rpath,$(GMP_SRC_DIR)/.libs

clean:
	$(MAKE) -C $(GMP_SRC_DIR) clean || true
	$(MAKE) -C $(M4_SRC_DIR) clean || true
	rm -f $(TARGET)
