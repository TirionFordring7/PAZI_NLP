#include <iostream>
#include <vector>
#include <bitset>
#include <cstdint>
#include <string>
#include <math.h>
#include <gmpxx.h>
#include <fstream>
#include <omp.h>

// Константы
const int REGISTER_LENGTH = 16; // Длина регистра
const int VARIABLE_COUNT = 7;   // Степень f 
const int SIGMA = 1; // Константа

struct NonlinearFunction {
    std::vector<int> mons; // Вектор где одним элементом является моном, представленный как битовая маска
};

// Функция для применения нелинейной функции к входным данным
int applyNonlinearFunction(const NonlinearFunction& func, const std::vector<int>& inputs) {
    int result = 0;
    for(auto mon = func.mons.begin(); mon != func.mons.end(); ++mon) {
        int monValue = 1;
        for(int i = 0; i < VARIABLE_COUNT; ++i) {
            if(*mon & (1 << i)) { // Проверка, присутствует ли переменная
                monValue &= inputs[i];
            }
        }
        result ^= monValue; // xor
    }
    return result;
}

// Функция обратной связи
std::bitset<REGISTER_LENGTH> puFunction(const std::bitset<REGISTER_LENGTH>& state, const NonlinearFunction& func) {
    // Вычисление нового бита
    int newBit = SIGMA; 
    // p(x) = x^16 + x^12 + x^3 + x + 1
    newBit ^= state[15]; 
    newBit ^= state[11];
    newBit ^= state[2]; 
    newBit ^= state[0];  
    // Извлечение значений переменных для нелинейной функции
    // Предполагаем, что переменные выбираются из битов первых 7 регистров
    std::vector<int> vars(VARIABLE_COUNT, 0);
    for(int j = 0; j < VARIABLE_COUNT; ++j) {
        vars[j] = state[j];
    }
    // Применение нелинейной функции
    int nonlinearOutput = applyNonlinearFunction(func, vars);
    // xor результат нелинейной функции в новый бит
    newBit ^= nonlinearOutput;
    // Сдвиг регистра и добавление нового бита
    std::bitset<REGISTER_LENGTH> newState = state << 1;
    newState[0] = newBit;
    return newState;
}

std::bitset<REGISTER_LENGTH> puSecondPolFunction(const std::bitset<REGISTER_LENGTH>& state, const NonlinearFunction& func) {
    // Вычисление нового бита
    int newBit = SIGMA; 
    // p(x) = x^16 + x^12 + x^3 + x + 1
    newBit ^= state[15]; 
    newBit ^= state[13];
    newBit ^= state[12]; 
    newBit ^= state[10];  
    // Извлечение значений переменных для нелинейной функции
    // Предполагаем, что переменные выбираются из битов первых 7 регистров
    std::vector<int> vars(VARIABLE_COUNT, 0);
    for(int j = 0; j < VARIABLE_COUNT; ++j) {
        vars[j] = state[j];
    }
    // Применение нелинейной функции
    int nonlinearOutput = applyNonlinearFunction(func, vars);
    // xor результат нелинейной функции в новый бит
    newBit ^= nonlinearOutput;
    // Сдвиг регистра и добавление нового бита
    std::bitset<REGISTER_LENGTH> newState = state << 1;
    newState[0] = newBit;
    return newState;
}

void processNonlinearFunction(const NonlinearFunction& func, std::ofstream& outFile) {
    unsigned int input = 43767; // Случайное инициализирующее значение регистра
    std::bitset<REGISTER_LENGTH> state(input);
    int period = 0;
    int periodsec = 0;
    
    for(uint16_t i = 1; i < (pow(2,REGISTER_LENGTH)); ++i) {
        std::bitset<REGISTER_LENGTH> outputState = puFunction(state, func);
        uint16_t output = outputState.to_ulong();
        period = i;
        if(input == output) {
            break;
        }
        state = output;
    }
    
    if(period >= 65535) {
        std::string result = "Нелинейная функция(первой пробы) f: ";
        for(auto it = func.mons.begin(); it != func.mons.end(); ++it) {
            result += "x";
            for(int i = 0; i < VARIABLE_COUNT; ++i) {
                if((*it) & (1 << i)) {
                    result += std::to_string(i+1);
                }
            }
            if(std::next(it) != func.mons.end()) {
                result += " + ";
            }
        }
        result += " Период равен: " + std::to_string(period) + "\n";

                // Вывод в файл и на экран
        #pragma omp critical
        {
            outFile << result;
            std::cout << result;
        }
    }

    state = input;

    if(period >= 65535) {
        for(uint16_t i = 1; i < (pow(2,REGISTER_LENGTH)); ++i) {
            std::bitset<REGISTER_LENGTH> outputState = puSecondPolFunction(state, func);
            uint16_t output = outputState.to_ulong();
            periodsec = i;
            if(input == output) {
                break;
            }
            state = output;
    }
    }

    // Выводим результат только если период максимальный
    if(periodsec >= 65535) {
        std::string result = "Нелинейная функция(второй пробы) f: ";
        for(auto it = func.mons.begin(); it != func.mons.end(); ++it) {
            result += "x";
            for(int i = 0; i < VARIABLE_COUNT; ++i) {
                if((*it) & (1 << i)) {
                    result += std::to_string(i+1);
                }
            }
            if(std::next(it) != func.mons.end()) {
                result += " + ";
            }
        }
        result += " Период равен: " + std::to_string(period) + "\n";
        
        // Вывод в файл и на экран
        #pragma omp critical
        {
            outFile << result;
            std::cout << result;
        }
        

        
    }
}

void generateAndTestNonlinearFunctions(int variableCount) {
    std::ofstream outFile("nonlinear_functions_per65535.txt", std::ios::app); 
    // Используем gmp для больших чисел
    int maxComb = (1 << variableCount) - 1;

    // Вычисляем максимальное количество итераций
    mpz_class maxIterations;
    maxIterations = 1;
    maxIterations <<= (maxComb-1);
    maxIterations -= 1;

    std::cout << "Всего возможных комбинаций: " << maxIterations << "\n";
    int num_threads = omp_get_max_threads();
    mpz_class chunk_size = maxIterations / num_threads;
    
    // Используем строковое представление для итерации по большим числам
    #pragma omp parallel
    {
        // Разрезаем общее количество итераций на количество логических ядер эвм, что бы в зависимости от номера потока он начинал считать с соответствующего места
        int thread_id = omp_get_thread_num();
        mpz_class start = thread_id * chunk_size;
        mpz_class end = 0;
        if(thread_id == num_threads - 1){
            end = maxIterations;
        }else{
            end = start + chunk_size;
        }
        for(mpz_class i = start; i < end; ++i) {
            NonlinearFunction func;
            func.mons.push_back(127); // Добавляем обязательный член x1x2x3x4x5x6x7 так как степень 7
        
            for(int j = 0; j < maxComb; ++j) {
                // Проверяем бит в большом числе
                if(mpz_tstbit(i.get_mpz_t(), j)) {
                    int bitCount = 0;
                    int mon = j + 1;
                
                    // Подсчёт битов можно оставить для малых чисел, так как mon всё ещё умещается в int 
                    for(int k = 0; k < variableCount; ++k) {
                        if(mon & (1 << k)) bitCount++;
                    }
                
                    if(bitCount < variableCount) {
                        func.mons.push_back(mon);
                    }
                }
            }
        
            processNonlinearFunction(func,outFile);
        
            // Выводим прогресс каждые 10000 итераций
            if(mpz_divisible_ui_p(i.get_mpz_t(), 10000)) {
                #pragma omp critical
                {
                    std::cout << "Поток " << thread_id << ": Обработано функций: " << i << " из " << end << "\r";
                    std::cout.flush();
                }
            }
        }
    }
    outFile.close();
}

int main() {
    omp_set_num_threads(48);
    std::cout << "Начинаем генерацию и тестирование нелинейных функций...\n";
    generateAndTestNonlinearFunctions(VARIABLE_COUNT);
    return 0;
}