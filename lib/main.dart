/// Bryan Perez
/// University of Texas at El Paso

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// **Main function that initializes the Flutter application.**
///
/// This function is the entry point of the application, calling `runApp()`
/// to launch the `WeatherApp` widget.
void main() {
  runApp(const WeatherApp());
}

/// **Root widget of the weather application.**
///
/// This stateless widget initializes the MaterialApp and sets up the application's
/// theme and home screen.
///
/// ### Features:
/// - Disables debug banner (`debugShowCheckedModeBanner: false`)
/// - Sets app title to `"UTEP 7-Day Weather Forecast"`
/// - Applies a blue primary color theme
/// - Loads `WeatherScreen` as the home screen
class WeatherApp extends StatelessWidget {
  /// **Constructor for WeatherApp.**
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UTEP 7-Day Weather Forecast',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WeatherScreen(),
    );
  }
}

/// **Main screen of the weather application displaying a 7-day forecast.**
///
/// This stateful widget is responsible for:
/// - Fetching weather data from the Open-Meteo API.
/// - Displaying the retrieved weather forecast.
/// - Handling API errors and showing appropriate messages.
class WeatherScreen extends StatefulWidget {
  /// **Constructor for WeatherScreen.**
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

/// **State class for `WeatherScreen`.**
///
/// This class manages:
/// - Fetching weather data asynchronously from the Open-Meteo API.
/// - Parsing the API response and updating the UI.
/// - Handling loading states and error messages.
class WeatherScreenState extends State<WeatherScreen> {
  /// **Open-Meteo API URL for UTEP’s weather forecast.**
  ///
  /// This URL fetches:
  /// - **Latitude:** 31.77 (UTEP)
  /// - **Longitude:** -106.50 (UTEP)
  /// - **Daily Weather Code:** Returns a list of weather codes for the next 7 days.
  /// - **Timezone:** Auto-detected based on location.
  final String apiUrl =
      "https://api.open-meteo.com/v1/forecast?latitude=31.77&longitude=-106.50&daily=weather_code&timezone=auto";

  /// **Stores the parsed weather forecast data.**
  ///
  /// Each entry in the list contains:
  /// - `"date"` (String): The forecast date.
  /// - `"weatherCode"` (int): The weather condition code.
  /// - `"description"` (String): Human-readable weather description.
  List<Map<String, dynamic>> _forecast = [];

  /// **Boolean flag indicating whether the app is fetching data.**
  bool _isLoading = true;

  /// **Stores an error message in case of API failure.**
  ///
  /// If `null`, there are no errors.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  /// **Fetches weather data from the Open-Meteo API and updates the UI.**
  ///
  /// This method:
  /// - Sends an HTTP GET request to fetch weather data.
  /// - Parses the JSON response and extracts `time` (dates) and `weather_code` values.
  /// - Converts weather codes to human-readable descriptions using `getWeatherDescription()`.
  /// - Updates `_forecast` and triggers a UI refresh.
  ///
  /// **Error Handling:**
  /// - If the API request fails, it sets `_errorMessage` and prevents app crashes.
  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List dates = data["daily"]["time"];
        final List weatherCodes = data["daily"]["weather_code"];

        List<Map<String, dynamic>> forecastData = [];
        for (int i = 0; i < dates.length; i++) {
          forecastData.add({
            "date": dates[i],
            "weatherCode": weatherCodes[i],
            "description": getWeatherDescription(weatherCodes[i]),
          });
        }

        setState(() {
          _forecast = forecastData;
          _isLoading = false;
        });

        developer.log("Weather data loaded successfully", name: "WeatherApp");
      } else {
        throw Exception(
            "Failed to load weather data (HTTP ${response.statusCode})");
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load weather data. Please try again later.";
      });

      developer.log(
          "Error fetching weather: $error", name: "WeatherApp", error: error);
    }
  }

  /// **Converts weather codes into human-readable descriptions.**
  ///
  /// Weather codes are mapped based on Open-Meteo documentation.
  ///
  /// | Weather Code | Description |
  /// |-------------|-------------|
  /// | `0` | Clear sky ☀️ |
  /// | `1, 2, 3` | Partly cloudy ⛅ |
  /// | `45, 48` | Fog 🌫️ |
  /// | `51, 53, 55` | Drizzle 🌦️ |
  /// | `61, 63, 65` | Rain 🌧️ |
  /// | `71, 73, 75` | Snow ❄️ |
  /// | `80, 81, 82` | Rain showers 🌦️ |
  /// | `95, 96, 99` | Thunderstorm ⛈️ |
  ///
  /// Returns a **string description** with an emoji.
  String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return "Clear sky ☀️";
      case 1:
      case 2:
      case 3:
        return "Partly cloudy ⛅";
      case 45:
      case 48:
        return "Fog 🌫️";
      case 51:
      case 53:
      case 55:
        return "Drizzle 🌦️";
      case 61:
      case 63:
      case 65:
        return "Rain 🌧️";
      case 71:
      case 73:
      case 75:
        return "Snow ❄️";
      case 80:
      case 81:
      case 82:
        return "Rain showers 🌦️";
      case 95:
      case 96:
      case 99:
        return "Thunderstorm ⛈️";
      default:
        return "Unknown weather ❓";
    }
  }

  /// **Builds the UI for the weather forecast screen.**
  ///
  /// This method constructs the main interface of the app, displaying:
  /// - A **loading spinner** while fetching data.
  /// - An **error message** if the API request fails.
  /// - A **list of weather forecasts** (7 days) once data is loaded.
  ///
  /// ### UI Components:
  /// - **Scaffold**: Provides the main structure (AppBar, Body).
  /// - **AppBar**: Displays the title `"UTEP 7-Day Weather Forecast"`.
  /// - **CircularProgressIndicator**: Shown when `_isLoading == true`.
  /// - **Error Message**: Displays `_errorMessage` if API call fails.
  /// - **ListView.builder**: Generates a scrollable list of weather data.
  ///
  /// ### Returns:
  /// A `Widget` containing the weather forecast UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// **Top app bar with the app title.**
      appBar: AppBar(title: const Text("UTEP 7-Day Weather Forecast")),

      /// **Main content of the screen.**
      body: _isLoading

      /// **1️⃣ Shows a loading spinner while fetching data.**
          ? const Center(child: CircularProgressIndicator())

      /// **2️⃣ Displays an error message if API request fails.**
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
      )

      /// **3️⃣ Displays the weather forecast in a scrollable list.**
          : ListView.builder(
        itemCount: _forecast.length, // Number of days in forecast
        itemBuilder: (context, index) {
          final day = _forecast[index]; // Get forecast data for the day

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(

              /// **Leading widget (weather emoji).**
              leading: Text(
                day["description"]
                    .split(" ")
                    .last, // Extract emoji
                style: const TextStyle(fontSize: 24), // Larger emoji size
              ),

              /// **Title: Date of the weather forecast.**
              title: Text(day["date"]),

              /// **Subtitle: Weather description (e.g., "Rain 🌧️").**
              subtitle: Text(day["description"]),
            ),
          );
        },
      ),
    );
  }
}
