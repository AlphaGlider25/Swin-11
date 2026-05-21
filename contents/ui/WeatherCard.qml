import QtQuick
import QtCore
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmaCore.ColorScope {
    id: weatherCard

    colorGroup: PlasmaCore.ColorScope.Window
    visible: Plasmoid.configuration.showWeather
    height: visible ? 60 : 0
    width: parent.width

    property string temperature: "--°C"
    property string condition: "Unavailable"
    property string weatherIcon: "weather-clear"
    property var weatherCache: null
    property var lastUpdateTime: 0
    property int cacheValidityMs: 30 * 60 * 1000 // 30 minutes

    Rectangle {
        anchors.fill: parent
        color: PlasmaCore.ColorScope.backgroundColor
        radius: 4
        border.color: PlasmaCore.ColorScope.textColor
        border.width: 1

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
    }

    function updateWeather() {
        var now = Date.now();

        // Check cache validity
        if (weatherCache !== null && (now - lastUpdateTime) < cacheValidityMs) {
            applyWeatherData(weatherCache);
            return;
        }

        // Query KDE weather daemon via D-Bus
        var process = Qt.createQmlObject(
            "import QtCore; Process { }",
            weatherCard
        );

        // Use qdbus to query weather service
        process.program = "qdbus";
        process.arguments = [
            "org.kde.weather",
            "/weather",
            "org.kde.weather.WeatherProvider.currentWeather"
        ];

        process.finished.connect(function() {
            var output = process.readAllStandardOutput().toString();
            var error = process.readAllStandardError().toString();

            if (error || !output) {
                weatherCard.condition = "Weather unavailable — configure in System Settings";
                weatherCard.temperature = "";
                weatherCard.weatherIcon = "dialog-warning";
                process.destroy();
                return;
            }

            try {
                var data = JSON.parse(output);
                weatherCache = data;
                lastUpdateTime = now;
                applyWeatherData(data);
            } catch(e) {
                weatherCard.condition = "Error parsing weather data";
                weatherCard.temperature = "";
                weatherCard.weatherIcon = "dialog-error";
                console.error("Weather parsing error:", e);
            }
            process.destroy();
        });

        process.errorOccurred.connect(function() {
            weatherCard.condition = "Weather service unavailable";
            weatherCard.temperature = "";
            weatherCard.weatherIcon = "dialog-warning";
            console.warn("D-Bus query failed:", process.errorString());
            process.destroy();
        });

        try {
            process.start();
        } catch(e) {
            weatherCard.condition = "Cannot connect to weather service";
            weatherCard.temperature = "";
            weatherCard.weatherIcon = "dialog-error";
            console.error("Process start error:", e);
        }
    }

    function applyWeatherData(data) {
        if (data.temperature !== undefined) {
            weatherCard.temperature = Math.round(data.temperature) + "°C";
        }
        if (data.condition !== undefined) {
            weatherCard.condition = data.condition;
        }
        if (data.icon !== undefined) {
            weatherCard.weatherIcon = data.icon;
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
