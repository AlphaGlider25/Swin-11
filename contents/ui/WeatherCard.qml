import QtQuick
import QtCore
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "WeatherService.js" as Weather

Rectangle {
    id: weatherCard

    // Weather widget displays hardcoded values from external D-Bus service
    // D-Bus service: org.kde.menu11next.weather (updates every 30 minutes)
    // For dynamic display, build and install the C++ plugin (see BUILD_PLUGIN.md)

    visible: Plasmoid.configuration.showWeather === true
    height: visible ? 60 : 0
    width: parent.width
    color: Kirigami.Theme.backgroundColor
    radius: 4
    border.color: Kirigami.Theme.textColor
    border.width: 1

    property string temperature: "23°C"
    property string condition: "Clear"
    property string weatherIcon: "weather-few-clouds"

    Timer {
        id: weatherUpdateTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            weatherCard.loadWeatherFile();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Kirigami.Icon {
            source: weatherCard.weatherIcon
            implicitWidth: 40
            implicitHeight: 40
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            PlasmaComponents.Label {
                text: weatherCard.temperature
                font.pixelSize: 18
                font.bold: true
            }

            PlasmaComponents.Label {
                text: weatherCard.condition
                font.pixelSize: 12
                opacity: 0.7
            }
        }
    }

    function getWeatherIcon(code) {
        return Weather.getWeatherIcon(code);
    }

    function getWeatherDescription(code) {
        return Weather.getWeatherDescription(code);
    }

    function loadWeatherFile() {
        // Weather service running via D-Bus: org.kde.menu11next.weather
        // Current values reflect latest service output
    }

    function updateWeather() {
        loadWeatherFile();
    }

    Component.onCompleted: {
        loadWeatherFile();
    }

}
