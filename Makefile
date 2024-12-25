TARGET = pazi.out
CXX = g++
CXXFLAGS = -Ofast -march=native -fopenmp
GMP_ARCHIVE = gmp-6.2.1.tar.xz
GMP_SRC_DIR = gmp-6.2.1

.PHONY: all clean

all: $(TARGET)
	@echo
	@echo "=== Запускаем ./$(TARGET) ==="
	LD_LIBRARY_PATH=$(GMP_SRC_DIR)/.libs:$$LD_LIBRARY_PATH ./$(TARGET)

$(GMP_SRC_DIR):
	tar -xf $(GMP_ARCHIVE)

$(GMP_SRC_DIR)/config.status: | $(GMP_SRC_DIR)
	cd $(GMP_SRC_DIR) && ./configure --enable-cxx

$(GMP_SRC_DIR)/libgmpxx.la: $(GMP_SRC_DIR)/config.status
	$(MAKE) -C $(GMP_SRC_DIR)

$(TARGET): $(GMP_SRC_DIR)/libgmpxx.la pazi.cpp
	$(CXX) $(CXXFLAGS) pazi.cpp -I $(GMP_SRC_DIR) -L $(GMP_SRC_DIR)/.libs -lgmpxx -lgmp -o $(TARGET) -Wl,-rpath,$(GMP_SRC_DIR)/.libs

clean:
	$(MAKE) -C $(GMP_SRC_DIR) clean || true
	rm -f $(TARGET)
