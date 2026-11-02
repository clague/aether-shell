pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Weather location picker: results from the debounced search, plus the two flags that let
    // the list distinguish "still searching" from "no match".
    property list<var> locationResults: []
    property bool locationSearching: false
    property bool locationSearched: false

    // Temperature units (there must be one for each value of the TemperatureUnit enum)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: TemperatureUnit.Auto
        },
        MenuItem {
            text: Tr.tr("°C")
            value: TemperatureUnit.Celsius
        },
        MenuItem {
            text: Tr.tr("°F")
            value: TemperatureUnit.Fahrenheit
        },
        MenuItem {
            text: Tr.tr("K")
            value: TemperatureUnit.Kelvin
        }
    ]

    // Data size units (there must be one for each value of the DataUnit enum)
    readonly property list<MenuItem> dataItems: [
        MenuItem {
            text: Tr.tr("Binary (KiB, MiB)")
            value: DataUnit.Binary
        },
        MenuItem {
            text: Tr.tr("Decimal (KB, MB)")
            value: DataUnit.Decimal
        }
    ]

    // Clock formats (there must be one for each value of the ClockFormat enum)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: ClockFormat.Auto
        },
        MenuItem {
            text: Tr.tr("12-hour")
            value: ClockFormat.TwelveHour
        },
        MenuItem {
            text: Tr.tr("24-hour")
            value: ClockFormat.TwentyFourHour
        }
    ]

    function applyLocation(coords: string, name: string): void {
        GlobalConfig.services.weatherLocation = coords;
        locationSearch.text = "";
        root.locationResults = [];
        root.locationSearched = false;
        Toaster.toast(Tr.tr("Weather location"), name, "location_on");
    }

    function useAutomaticLocation(): void {
        GlobalConfig.services.weatherLocation = "";
        locationSearch.text = "";
        root.locationResults = [];
        root.locationSearched = false;
    }

    title: Tr.tr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: Tr.tr("Language")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("UI language")
            subtext: Tr.tr("The language used in the shell UI")
            active: menuItems.find(i => i.modelData === Tr.language) ?? autoLang
            onSelected: item => {
                Tr.language = item.modelData ?? ""; // qmllint disable missing-property
            }

            menuItems: [autoLang, ...langItems.instances]

            MenuItem {
                id: autoLang

                text: Tr.tr("Auto")
            }

            Variants {
                id: langItems

                model: Tr.supportedLanguages

                MenuItem {
                    required property string modelData

                    text: {
                        const locale = Qt.locale(modelData);
                        return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                    }
                }
            }
        }

        // Weather
        SectionHeader {
            text: Tr.tr("Weather")
        }

        StyledTextField {
            id: locationSearch

            Layout.fillWidth: true
            placeholderText: Tr.tr("Search for a city")
            leadingIcon: "search"
            inputMethodHints: Qt.ImhNoPredictiveText
            onTextChanged: locationSearchTimer.restart()
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.locationSearching || (root.locationSearched && root.locationResults.length === 0)
            text: root.locationSearching ? Tr.tr("Searching…") : Tr.tr("No matching city")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        // One row per match: a city name alone is ambiguous (there are dozens of Springfields),
        // so the region is shown and the choice is an explicit click rather than "first hit".
        Repeater {
            model: root.locationResults

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.locationResults.length - 1
                icon: "location_on"
                text: modelData.name
                subtext: [modelData.admin1, modelData.country].filter(part => part.length > 0).join(", ")
                onClicked: root.applyLocation(modelData.coords, modelData.name)
            }
        }

        RowButton {
            first: root.locationResults.length === 0
            last: true
            icon: "my_location"
            text: Tr.tr("Automatic location")
            subtext: Tr.tr("Use the location your network provider reports")
            trailingIcon: GlobalConfig.services.weatherLocation === "" ? "check" : ""
            onClicked: root.useAutomaticLocation()
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            text: GlobalConfig.services.weatherLocation === "" ? Tr.tr("Currently using the automatic location") : Tr.tr("Currently set to %1").arg(Weather.city || GlobalConfig.services.weatherLocation)
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        // Units
        SectionHeader {
            text: Tr.tr("Units")
        }

        SelectRow {
            first: true
            label: Tr.tr("Temperature")
            subtext: Tr.tr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.weatherUnits)
            onSelected: item => GlobalConfig.services.weatherUnits = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("System temperatures")
            subtext: Tr.tr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.sensorUnits)
            onSelected: item => GlobalConfig.services.sensorUnits = item.value
        }

        // Time & date
        SectionHeader {
            text: Tr.tr("Time & date")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Clock format")
            subtext: Tr.tr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems.find(i => i.value === GlobalConfig.services.clockFormat)
            onSelected: item => GlobalConfig.services.clockFormat = item.value
        }
        Timer {
            id: locationSearchTimer

            interval: 350
            onTriggered: {
                const query = locationSearch.text;
                if (query.trim().length < 2) {
                    root.locationSearching = false;
                    root.locationSearched = false;
                    root.locationResults = [];
                    return;
                }

                root.locationSearching = true;
                Weather.searchCities(query, results => {
                    // Drop a response that arrived after the field changed again.
                    if (locationSearch.text !== query)
                        return;
                    root.locationSearching = false;
                    root.locationSearched = true;
                    root.locationResults = results;
                });
            }
        }
    }
}
