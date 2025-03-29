#!/bin/bash

setDir() {
    echo "Введите путь до вашего проекта(либо с '/' либо с '~')"
    read -e TempDir
    TempDir=$(echo "$TempDir" | sed "s|~|$HOME|")
    echo "Верно?(y/n)"
    read RightDir
    RightDirFunc $RightDir $TempDir
}

RightDirFunc() {
    if [[ "$1" == "n" ]]; then
        setDir n
    else
        export TempDir
    fi
}

CreateCMakeLists() {
    # Создание самого файла
    touch $ProjectDir/CMakeLists.txt
    echo "Был создан файл CMakeLists.txt"

    # Указание минимальной версии cmake
    correct="n"
    while [ $correct != "y" ]; do
        echo "Введите минимальную версию cmake(по умолчанию 3.5.0)"
        read -t 15 Version
        if [[ "$Version" == "" ]]; then
            Version="3.5.0"
        fi
        echo -e "Выбрана версия: $Version\nУстраивает?(y/n)"
        read -t 4 correct
    done

    echo "cmake_minimum_required(VERSION $Version)\
 # минимальная версия cmake" >>$ProjectDir/CMakeLists.txt
    
    # Указание имени проекта
    echo "Введите название вашего проекта(по умолчанию Another_Project)"
    read -t 20 ProjectName
    if [[ "$ProjectName" == "" ]]; then
        ProjectName="Another_Project"
    fi
    echo -e "project($ProjectName) \
 # название проекта\n" >>$ProjectDir/CMakeLists.txt

    # Указание исходных файлов для проекта
    echo "set(SRC_FILES\
 # переменная с именами исходников" >>$ProjectDir/CMakeLists.txt

    echo "Введите название главного(main) файла"
    read NameMain
    echo "    $NameMain" >>$ProjectDir/CMakeLists.txt

    echo "У вас уже имеются исходные файлы?(y/n)"
    read HaveIshodniks

    if [[ $HaveIshodniks == "y" ]]; then
        echo -e "Введите название(я) каталога(ов) с исходниками\nЕсли они в корне проекта, то напишите \".\""
        read DirsWithIsh
        if [[ "$DirsWithIsh" == "." ]]; then
            DirsWithIsh=$ProjectDir
        fi

    for kat in $DirsWithIsh; do
        for files in $(find $ProjectDir/$kat -name "*.c**"); do
            echo $files | sed "s|$ProjectDir/|    |"\
>>$ProjectDir/CMakeLists.txt
        done
    done

    HaveBuild=$(find $ProjectDir -type d | grep "build"$)
    if [[ "$HaveBuild" == "" ]]; then
        mkdir $ProjectDir/build
        cmake $ProjectDir -B $ProjectDir/build -S $ProjectDir >/dev/null
    fi
        
    else
        echo "Хотите создать скелет вашего проекта?(y/n)"
        read CreateSkelet
        if [[ "$CreateSkelet" == "y" || "$CreateSkelet" == "" ]]; then
            mkdir $ProjectDir/src $ProjectDir/header $ProjectDir/build
            touch $ProjectDir/$NameMain
            echo -e "Были созданы каталоги:\n\tsrc(для реализаций)\n\theader(для заголовочных файлов)\n\tbuild(техническая)"
            echo -e "файлы:\n\t$NameMain"
        fi
    fi

    echo -e ")\n" >>$ProjectDir/CMakeLists.txt
    echo 'add_executable(${PROJECT_NAME} ${SRC_FILES}) # название итогого приложения и из чего его собирать' >>$ProjectDir/CMakeLists.txt

    cd $ProjectDir/build
    cmake ..
    make 2>/dev/null
    cd $CurrentDir

    echo -e "\nРезультаты работы скрипта:
был создан CMakeLists.txt с такими параметрами:
    минимальная версия cmake -- $Version
    название проекта -- $ProjectName"
}

#=======================================

ChangeName() {
    sed -i "s/project(.*)/project($1)/" $ProjectDir/CMakeLists.txt
}

ChangeVersion() {
    sed -i "s/cmake_minimum_required(.*)/cmake_minimum_required(VERSION $1)/" $ProjectDir/CMakeLists.txt
}

AddIsh () {
    sed -i "s/^set(SRC_FILES"
}

EditCMakeLists() {
    operation=0
    echo -e "0 - изменить имя\n\
1 - изменить версию\n\
2 - добавить исходник\n"

    read -t 10 operation
    if (( operation == 0 )); then
        read -p "Введите новое имя проекта: " newName
        ChangeName $newName

    elif (( operation == 1 )); then
        read -p "Введите минимальную версию cmake: " newVersion
        ChangeVersion $newVersion

    elif (( operation == 2 )); then
        read -p "Введите путь до исходника вида \"src/tandem.cpp\": " path
        AddIsh $path
    fi
}

# НАЧАЛО СКРИПТА

CurrentDir=$(pwd)
ProjectDir=""

# получение рабочей директории
echo -e "$CurrentDir\nтекущая директория проекта?(y/n)"
read RightDir
if [[ "$RightDir" == "y" || "$RightDir" == "" ]]; then
    ProjectDir=$CurrentDir
else
    setDir
    ProjectDir=$TempDir
fi

# поиск CMakeLists.txt
if [ $# == 0 ]; then
    status=$(find $ProjectDir -name "CMakeLists.txt")

    if [[ "$status" == "" ]]; then # Если не найден
        CreateCMakeLists
    else # Если найден
        echo "Желаете изменить CMakeLists?(y/n)"
        read GetChange
        if [[ "$GetChange" == "y" || "$GetChange" == "" ]]; then
            EditCMakeLists
        fi
    fi
fi
