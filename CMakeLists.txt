cmake_minimum_required(VERSION 3.16)

project(samegame)

set(QT_MIN_VERSION "6.4.0")

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Svg Sql Multimedia)
qt_standard_project_setup()

################# build and install #################
add_subdirectory(src)

if(UNIX AND NOT APPLE AND NOT ANDROID)
    include(GNUInstallDirs)
    install(PROGRAMS org.kde.samegame.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES org.kde.samegame.appdata.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
endif()
