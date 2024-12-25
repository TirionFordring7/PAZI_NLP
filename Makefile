# Имя целевого бинарника
TARGET = pazi.out

# Параметры компиляции
CXX      = g++
CXXFLAGS = -Ofast -march=native -fopenmp

# Название архива GMP и директории, в которую он распакуется
GMP_ARCHIVE = gmp-6.2.1.tar.xz
GMP_SRC_DIR = gmp-6.2.1

.PHONY: all clean

all: $(TARGET)
\t@echo
\t@echo "=== Запускаем ./$(TARGET) ==="
\t./$(TARGET)

# 1) Проверяем, есть ли директория gmp-6.2.1, если нет - распаковываем
$(GMP_SRC_DIR):
\ttar -xf $(GMP_ARCHIVE)

# 2) Конфигурируем GMP (создаём config.status как 'маяк', что конфигурация прошла)
$(GMP_SRC_DIR)/config.status: | $(GMP_SRC_DIR)
\tcd $(GMP_SRC_DIR) && ./configure --enable-cxx

# 3) Собираем GMP (создаём libgmpxx.la как 'маяк', что сборка прошла)
$(GMP_SRC_DIR)/libgmpxx.la: $(GMP_SRC_DIR)/config.status
\t$(MAKE) -C $(GMP_SRC_DIR)

# 4) Собираем наш pazi.out, слинкованный с уже собранными в gmp-6.2.1/.libs библиотеками
$(TARGET): $(GMP_SRC_DIR)/libgmpxx.la pazi.cpp
\t$(CXX) $(CXXFLAGS) pazi.cpp -I $(GMP_SRC_DIR) -L $(GMP_SRC_DIR)/.libs -lgmpxx -lgmp -o $(TARGET)

clean:
\t$(MAKE) -C $(GMP_SRC_DIR) clean || true
\trm -f $(TARGET)

