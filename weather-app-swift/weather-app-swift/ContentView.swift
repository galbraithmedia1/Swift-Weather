//
//  ContentView.swift
//  weather-app-swift
//
//  Created by Taylor Galbraith on 12/28/24.
//

import SwiftUI

// MARK: - Models
struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
    }
}

struct Weather: Codable {
    let description: String
    let icon: String
}

// MARK: - View Models
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherResponse?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let apiKey = "KEY" // Replace with your OpenWeather API key
    
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            errorMessage = "Invalid city name"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let weather = try decoder.decode(WeatherResponse.self, from: data)
                    self?.currentWeather = weather
                } catch {
                    self?.errorMessage = "Failed to decode weather data"
                }
            }
        }.resume()
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var cityName = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Weather App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    TextField("Enter city name", text: $cityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                    
                    Button(action: {
                        if !cityName.isEmpty {
                            viewModel.fetchWeather(for: cityName)
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let weather = viewModel.currentWeather {
                    WeatherView(weather: weather)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct WeatherView: View {
    let weather: WeatherResponse
    
    var body: some View {
        VStack(spacing: 15) {
            Text(weather.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let weatherInfo = weather.weather.first {
                AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(weatherInfo.icon)@2x.png")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                } placeholder: {
                    ProgressView()
                }
                
                Text(weatherInfo.description.capitalized)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 20) {
                WeatherInfoView(
                    icon: "thermometer",
                    title: "Temperature",
                    value: String(format: "%.1f°f", weather.main.temp)
                )
                
                WeatherInfoView(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(weather.main.humidity)%"
                )
                
                WeatherInfoView(
                    icon: "thermometer.sun",
                    title: "Feels Like",
                    value: String(format: "%.1f°C", weather.main.feelsLike)
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .padding()
    }
}

struct WeatherInfoView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

