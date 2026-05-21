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
    property int cacheValidityMs: 30 * 60 * 1000 // 30 minutes
    property double latitude: 48.8566
    property double longitude: 2.3522

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
        if (code === 0) return "weather-clear";
        if (code === 1 || code === 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code >= 51 && code <= 67) return "weather-rain";
        if (code >= 71 && code <= 86) return "weather-snow";
        if (code >= 80 && code <= 82) return "weather-rain";
        if (code >= 90 && code <= 99) return "weather-thunderstorm";
        return "weather-clouds";
    }

    function getWeatherDescription(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly Clear";
        if (code === 2) return "Partly Cloudy";
        if (code === 3) return "Overcast";
        if (code === 45) return "Foggy";
        if (code >= 51 && code <= 67) return "Rain";
        if (code >= 71 && code <= 86) return "Snow";
        if (code >= 80 && code <= 82) return "Rainy";
        if (code >= 90 && code <= 99) return "Thunderstorm";
        return "Unknown";
    }

    function updateWeather() {
        var now = Date.now();

        if (weatherCache !== null && (now - lastUpdateTime) < cacheValidityMs) {
            applyWeatherData(weatherCache);
            return;
        }

        var process = Qt.createQmlObject(
            "import QtCore; Process { }",
            weatherCard
        );

        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude +
                  "&longitude=" + longitude +
                  "&current=temperature_2m,weather_code&timezone=auto";

        process.program = "curl";
        process.arguments = ["-s", url];

        process.finished.connect(function() {
            var output = process.readAllStandardOutput().toString();
            if (output) {
                try {
                    var response = JSON.parse(output);
                    var data = response.current;
                    weatherCache = data;
                    lastUpdateTime = now;
                    applyWeatherData(data);
                } catch(e) {
                    weatherCard.condition = "Parse error";
                    console.error("Weather parsing error:", e);
                }
            } else {
                weatherCard.condition = "Offline";
            }
            process.destroy();
        });

        process.errorOccurred.connect(function() {
            weatherCard.condition = "Network error";
            process.destroy();
        });

        try {
            process.start();
        } catch(e) {
            weatherCard.condition = "Error";
        }
    }

    function applyWeatherData(data) {
        if (data.temperature_2m !== undefined) {
            weatherCard.temperature = Math.round(data.temperature_2m) + "°C";
        }
        if (data.weather_code !== undefined) {
            weatherCard.condition = getWeatherDescription(data.weather_code);
            weatherCard.weatherIcon = getWeatherIcon(data.weather_code);
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
