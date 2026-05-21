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

    property string temperature: "--°C"
    property string condition: "Unavailable"
    property string weatherIcon: "weather-clouds"
    property var weatherCache: null
    property var lastUpdateTime: 0
    property int cacheValidityMs: 30 * 60 * 1000

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Kirigami.Icon {
            id: weatherIconItem
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
        if (code === 0) return "weather-clear";
        if (code <= 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code < 70) return "weather-rain";
        if (code < 80) return "weather-snow";
        if (code < 85) return "weather-rain";
        if (code < 90) return "weather-snow";
        return "weather-thunderstorm";
    }

    function getWeatherDescription(code) {
        code = parseInt(code);
        if (code === 0) return "Clear";
        if (code === 1) return "Clear";
        if (code === 2) return "Cloudy";
        if (code === 3) return "Overcast";
        if (code < 50) return "Fog";
        if (code < 70) return "Rain";
        if (code < 80) return "Snow";
        if (code < 85) return "Rain";
        if (code < 90) return "Snow";
        return "Thunderstorm";
    }

    function updateWeather() {
        var now = Math.floor(Date.now() / 1000);

        if (weatherCache && lastUpdateTime && (now - lastUpdateTime) < 1800) {
            applyWeatherData(weatherCache);
            return;
        }

        var proc = Qt.createQmlObject("import QtCore; Process{}", weatherCard);

        proc.finished.connect(function() {
            var json = proc.readAllStandardOutput().toString().trim();
            if (json.length > 0) {
                try {
                    var obj = JSON.parse(json);
                    weatherCache = obj;
                    lastUpdateTime = now;
                    applyWeatherData(obj);
                } catch(e) {
                    weatherCard.condition = "Error";
                }
            }
            proc.destroy();
        });

        proc.program = "/bin/bash";
        proc.arguments = ["-c",
            "curl -s 'https://api.open-meteo.com/v1/forecast?latitude=48.8566&longitude=2.3522&current=temperature_2m,weather_code' | " +
            "jq -r '.current | {temperature: .temperature_2m, code: .weather_code}' | jq -c ."
        ];

        try {
            proc.start();
        } catch(e) {
            weatherCard.condition = "Failed";
        }
    }

    function applyWeatherData(data) {
        if (data.temperature !== undefined) {
            weatherCard.temperature = Math.round(data.temperature) + "°C";
        }
        if (data.code !== undefined) {
            weatherCard.condition = getWeatherDescription(data.code);
            weatherCard.weatherIcon = getWeatherIcon(data.code);
        }
    }

    Component.onCompleted: {
        updateWeather();
    }

    onVisibleChanged: {
        if (visible) {
            updateWeather();
        }
    }
}
