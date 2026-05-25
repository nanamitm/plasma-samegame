add_executable(samegame main.cpp)

qt_add_resources(samegame "app_resources"
    PREFIX "/"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES
        contents/ui/samegame.qml
        contents/ui/BoomBlock.qml
        contents/ui/Dialog.qml
        contents/ui/samegame.js
        contents/ui/sounds/bgm.ogg
        contents/ui/sounds/pop.ogg
        contents/ui/sounds/click.ogg
        contents/ui/sounds/clear.ogg
        contents/ui/sounds/failure.ogg
        contents/ui/shared/pics/background.jpg
        contents/ui/shared/pics/blueStar.png
        contents/ui/shared/pics/blueStone.svg
        contents/ui/shared/pics/greenStar.png
        contents/ui/shared/pics/greenStone.svg
        contents/ui/shared/pics/redStar.png
        contents/ui/shared/pics/redStone.svg
        contents/ui/shared/pics/star.png
        contents/ui/shared/pics/yellowStone.png)

target_link_libraries(samegame PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Svg
    Qt::Sql
    Qt::Multimedia)


include(GNUInstallDirs)
install(TARGETS samegame
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE  DESTINATION .)
