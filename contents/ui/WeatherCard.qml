import QtQuick
import QtCore
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Rectangle {
    id: weatherCard

    visible: Plasmoid.configuration.showWeather === true
    height: visible ? 60 : 0
    width: parent.width
    color: Kirigami.Theme.backgroundColor
    radius: 4
    border.color: Kirigami.Theme.textColor
    border.width: 1

    property string temperature: "23°C"
    property string condition: "Partly Cloudy"
    property string weatherIcon: "weather-few-clouds"


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
        code = parseInt(code);
        if (code < 3) return "weather-few-clouds";
        if (code < 50) return "weather-overcast";
        if (code < 70) return "weather-rain";
        if (code < 85) return "weather-snow";
        return "weather-thunderstorm";
    }

    function getWeatherDescription(code) {
        code = parseInt(code);
        if (code < 3) return "Clear";
        if (code < 5) return "Cloudy";
        if (code < 50) return "Fog";
        if (code < 70) return "Rainy";
        if (code < 85) return "Snow";
        return "Storm";
    }

}
